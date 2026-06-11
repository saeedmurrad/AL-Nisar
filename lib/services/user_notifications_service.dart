import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// In-app notifications for members (e.g. Sabaq access approved/denied).
class UserNotificationsService {
  UserNotificationsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get _ready => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  Future<void> notifySabaqRequestApproved({
    required String userId,
    required String requestId,
    required String sabaqTitle,
    required String sabaqId,
  }) async {
    if (!_ready || userId.isEmpty) return;
    final title = sabaqTitle.trim().isNotEmpty ? sabaqTitle.trim() : 'Sabaq';
    await _col(userId).doc('${requestId}_approved').set({
      'type': 'sabaq_approved',
      'requestId': requestId,
      'sabaqId': sabaqId,
      'title': 'Sabaq access approved',
      'body': 'Your request to access "$title" has been approved. You can now read this Sabaq.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    }, SetOptions(merge: true));
  }

  Future<void> notifySabaqRequestDenied({
    required String userId,
    required String requestId,
    required String sabaqTitle,
    required String sabaqId,
  }) async {
    if (!_ready || userId.isEmpty) return;
    final title = sabaqTitle.trim().isNotEmpty ? sabaqTitle.trim() : 'Sabaq';
    await _col(userId).doc('${requestId}_denied').set({
      'type': 'sabaq_denied',
      'requestId': requestId,
      'sabaqId': sabaqId,
      'title': 'Sabaq access not approved',
      'body': 'Your request to access "$title" was not approved at this time.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    }, SetOptions(merge: true));
  }

  Stream<List<UserNotificationDoc>> streamForUser(String userId, {int limit = 40}) {
    if (!_ready || userId.isEmpty) return Stream.value(const []);
    return _col(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(UserNotificationDoc.fromFirestore).toList());
  }
}

class UserNotificationDoc {
  const UserNotificationDoc({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    required this.type,
    this.sabaqId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String type;
  final String? sabaqId;

  factory UserNotificationDoc.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    if (ts is Timestamp) createdAt = ts.toDate();
    return UserNotificationDoc(
      id: doc.id,
      title: d['title'] as String? ?? 'Notification',
      body: d['body'] as String? ?? '',
      createdAt: createdAt,
      read: d['read'] as bool? ?? false,
      type: d['type'] as String? ?? '',
      sabaqId: d['sabaqId'] as String?,
    );
  }
}
