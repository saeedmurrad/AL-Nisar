import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sabaq_access_request_model.dart';
import '../models/sabaq_pdf_model.dart';
import 'admin_notifications_service.dart';
import 'user_notifications_service.dart';

class SabaqAccessService {
  SabaqAccessService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String requestDocId(String userId, String sabaqId) => '${userId}__$sabaqId';

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('sabaq_access_requests');

  DocumentReference<Map<String, dynamic>> _userAccessDoc(String userId, String sabaqId) {
    return _firestore.collection('users').doc(userId).collection('sabaq_access').doc(sabaqId);
  }

  Stream<bool> streamHasAccess(String userId, String sabaqId) {
    return _userAccessDoc(userId, sabaqId).snapshots().map((d) {
      final data = d.data() ?? {};
      return (data['granted'] as bool?) == true;
    });
  }

  Future<bool> hasAccess(String userId, String sabaqId) async {
    final d = await _userAccessDoc(userId, sabaqId).get();
    final data = d.data() ?? {};
    return (data['granted'] as bool?) == true;
  }

  Future<void> requestAccess(
    SabaqPdfModel sabaq, {
    String? message,
    String? displayName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('not_signed_in');

    final id = requestDocId(user.uid, sabaq.id);
    final name = (displayName ?? user.displayName ?? '').trim();
    final existing = await _requests.doc(id).get();
    final existingStatus =
        (existing.data()?['status'] as String? ?? '').toLowerCase();

    final payload = <String, dynamic>{
      'userId': user.uid,
      'sabaqId': sabaq.id,
      'titleEn': sabaq.titleEn,
      'titleUr': sabaq.titleUr,
      'userEmail': user.email ?? '',
      'userName': name,
      'message': message?.trim() ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      await _requests.doc(id).set(payload);
    } else if (existingStatus == 'denied') {
      await _requests.doc(id).update({
        'userName': name,
        'userEmail': user.email ?? '',
        'message': message?.trim() ?? '',
        'status': 'pending',
        'decidedAt': FieldValue.delete(),
        'resubmittedAt': FieldValue.serverTimestamp(),
      });
    } else if (existingStatus == 'pending' || existingStatus == 'approved') {
      throw StateError('request_already_active');
    } else {
      throw StateError('request_already_active');
    }

    try {
      await AdminNotificationsService().notifySabaqRequestSubmitted(
        requestId: id,
        memberName: name,
        sabaqTitle: sabaq.titleEn,
        message: message,
      );
    } catch (_) {
      // Notification is best-effort (rules / offline).
    }
  }

  Stream<List<SabaqAccessRequestModel>> streamRequestsForUser(String userId) {
    return _requests.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final list = snap.docs.map(SabaqAccessRequestModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<SabaqAccessRequestModel>> streamPendingRequests() {
    return _requests.where('status', isEqualTo: 'pending').snapshots().map((snap) {
      final list = snap.docs.map(SabaqAccessRequestModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> approve(String requestId, {required String userId, required String sabaqId}) async {
    final reqSnap = await _requests.doc(requestId).get();
    final reqData = reqSnap.data() ?? {};
    final titleEn = reqData['titleEn'] as String? ?? '';

    final batch = _firestore.batch();
    batch.set(
      _userAccessDoc(userId, sabaqId),
      {
        'granted': true,
        'sabaqId': sabaqId,
        'grantedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _requests.doc(requestId),
      {'status': 'approved', 'decidedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await batch.commit();

    try {
      await AdminNotificationsService().dismissSabaqRequestNotification(requestId);
    } catch (_) {
      // Best-effort (rules / offline).
    }

    try {
      await UserNotificationsService().notifySabaqRequestApproved(
        userId: userId,
        requestId: requestId,
        sabaqTitle: titleEn,
        sabaqId: sabaqId,
      );
    } catch (_) {
      // Notification is best-effort (rules / offline).
    }
  }

  Future<void> deny(String requestId) async {
    final reqSnap = await _requests.doc(requestId).get();
    final reqData = reqSnap.data() ?? {};
    final userId = reqData['userId'] as String? ?? '';
    final sabaqId = reqData['sabaqId'] as String? ?? '';
    final titleEn = reqData['titleEn'] as String? ?? '';

    await _requests.doc(requestId).set(
      {'status': 'denied', 'decidedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );

    try {
      await AdminNotificationsService().dismissSabaqRequestNotification(requestId);
    } catch (_) {
      // Best-effort (rules / offline).
    }

    if (userId.isNotEmpty) {
      try {
        await UserNotificationsService().notifySabaqRequestDenied(
          userId: userId,
          requestId: requestId,
          sabaqTitle: titleEn,
          sabaqId: sabaqId,
        );
      } catch (_) {
        // Notification is best-effort (rules / offline).
      }
    }
  }
}
