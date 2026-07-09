import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sabaq_access_request_model.dart';
import '../models/sabaq_pdf_model.dart';
import '../utils/sabaq_order_utils.dart';
import 'admin_notifications_service.dart';
import 'user_notifications_service.dart';

class SabaqAccessService {
  SabaqAccessService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String requestDocId(String userId, String sabaqId) => '${userId}__$sabaqId';

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('sabaq_access_requests');

  DocumentReference<Map<String, dynamic>> _userAccessDoc(
    String userId,
    String sabaqId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sabaq_access')
        .doc(sabaqId);
  }

  CollectionReference<Map<String, dynamic>> _userAccessCol(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sabaq_access');
  }

  Stream<bool> streamHasAccess(String userId, String sabaqId) {
    return _userAccessDoc(userId, sabaqId).snapshots().map((d) {
      final data = d.data() ?? {};
      return (data['granted'] as bool?) == true;
    });
  }

  /// All Sabaq IDs the member currently has granted access to.
  Stream<Set<String>> streamGrantedSabaqIds(String userId) {
    return _userAccessCol(userId).snapshots().map((snap) {
      return snap.docs
          .where((d) => (d.data()['granted'] as bool?) == true)
          .map((d) => d.id)
          .toSet();
    });
  }

  Future<Set<String>> grantedSabaqIds(String userId) async {
    final snap = await _userAccessCol(userId).get();
    return snap.docs
        .where((d) => (d.data()['granted'] as bool?) == true)
        .map((d) => d.id)
        .toSet();
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
    List<SabaqPdfModel>? orderedSabaqs,
    Set<String>? grantedIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('not_signed_in');

    final ordered = orderedSabaqs ?? const <SabaqPdfModel>[];
    final grants = grantedIds ?? await grantedSabaqIds(user.uid);
    if (ordered.isNotEmpty) {
      final nextId = nextRequestableSabaqId(
        ordered: ordered,
        grantedIds: grants,
      );
      if (nextId == null || nextId != sabaq.id) {
        throw StateError('not_next_sabaq');
      }
    }

    final id = requestDocId(user.uid, sabaq.id);
    final name = (displayName ?? user.displayName ?? '').trim();
    final existing = await _requests.doc(id).get();
    final existingStatus = (existing.data()?['status'] as String? ?? '')
        .toLowerCase();

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

    // New request, or resubmit after denial only.
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
      // Unknown/legacy status: allow member to (re)open as pending.
      await _requests.doc(id).set({
        ...payload,
        'resubmittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
      final list = snap.docs
          .map(SabaqAccessRequestModel.fromFirestore)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<SabaqAccessRequestModel>> streamPendingRequests() {
    return _requests.where('status', isEqualTo: 'pending').snapshots().map((
      snap,
    ) {
      final list = snap.docs
          .map(SabaqAccessRequestModel.fromFirestore)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> approve(
    String requestId, {
    required String userId,
    required String sabaqId,
  }) async {
    final reqSnap = await _requests.doc(requestId).get();
    final reqData = reqSnap.data() ?? {};
    final titleEn = reqData['titleEn'] as String? ?? '';

    final batch = _firestore.batch();
    batch.set(_userAccessDoc(userId, sabaqId), {
      'granted': true,
      'sabaqId': sabaqId,
      'grantedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_requests.doc(requestId), {
      'status': 'approved',
      'decidedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();

    try {
      await AdminNotificationsService().dismissSabaqRequestNotification(
        requestId,
      );
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

    await _requests.doc(requestId).set({
      'status': 'denied',
      'decidedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await AdminNotificationsService().dismissSabaqRequestNotification(
        requestId,
      );
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
