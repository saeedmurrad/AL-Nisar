import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// In-app notifications for Super Admin (e.g. new Sabaq access requests).
class AdminNotificationsService {
  AdminNotificationsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get _ready => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('admin_notifications');

  Future<void> notifySabaqRequestSubmitted({
    required String requestId,
    required String memberName,
    required String sabaqTitle,
    String? message,
  }) async {
    if (!_ready) return;
    final name = memberName.trim().isNotEmpty ? memberName.trim() : 'A member';
    final title = sabaqTitle.trim().isNotEmpty ? sabaqTitle.trim() : 'Sabaq';
    final msg = message?.trim();
    final body = (msg != null && msg.isNotEmpty)
        ? '$name requested access to "$title". Message: $msg'
        : '$name requested access to "$title".';
    await _col.doc(requestId).set({
      'type': 'sabaq_request',
      'requestId': requestId,
      'title': 'New Sabaq access request',
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    }, SetOptions(merge: true));
  }

  /// Clears the super-admin alert for a resolved Sabaq access request.
  Future<void> dismissSabaqRequestNotification(String requestId) async {
    if (!_ready || requestId.trim().isEmpty) return;
    try {
      await _col.doc(requestId).delete();
    } catch (_) {
      // Rules may disallow delete; mark read so list + badge update.
      await _col.doc(requestId).set({'read': true}, SetOptions(merge: true));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (!_ready || notificationId.trim().isEmpty) return;
    await _col.doc(notificationId).set({'read': true}, SetOptions(merge: true));
  }

  Stream<List<AdminNotificationDoc>> streamRecent({int limit = 40}) {
    if (!_ready) return Stream.value(const []);
    // Equality filter only — no composite index required; sort client-side.
    return _col.where('read', isEqualTo: false).limit(limit).snapshots().map((
      snap,
    ) {
      final list = snap.docs.map(AdminNotificationDoc.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Removes admin alerts for Sabaq requests that are no longer pending.
  Future<void> pruneResolvedSabaqRequestNotifications() async {
    if (!_ready) return;
    final snap = await _col.where('read', isEqualTo: false).get();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['type'] != 'sabaq_request') continue;
      final requestId =
          (data['requestId'] as String?)?.trim().isNotEmpty == true
          ? data['requestId'] as String
          : doc.id;
      final req = await _firestore
          .collection('sabaq_access_requests')
          .doc(requestId)
          .get();
      final status = req.data()?['status'] as String? ?? '';
      if (!req.exists || status != 'pending') {
        await dismissSabaqRequestNotification(requestId);
      }
    }
  }

  Stream<int> streamUnreadCount() {
    if (!_ready) return Stream.value(0);
    return _col
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}

class AdminNotificationDoc {
  const AdminNotificationDoc({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  factory AdminNotificationDoc.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    if (ts is Timestamp) createdAt = ts.toDate();
    return AdminNotificationDoc(
      id: doc.id,
      title: d['title'] as String? ?? 'Notification',
      body: d['body'] as String? ?? '',
      createdAt: createdAt,
      read: d['read'] as bool? ?? false,
    );
  }
}
