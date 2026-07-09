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
      'body':
          'Your request to access "$title" has been approved. You can now read this Sabaq.',
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

  /// Notifies every user except [excludeUserId] when news is first published.
  Future<void> notifyAllUsersNewNews({
    required String newsId,
    required String title,
    required String excludeUserId,
  }) async {
    if (!_ready || newsId.trim().isEmpty) return;
    final displayTitle = title.trim().isNotEmpty ? title.trim() : 'News';
    final userIds = await _allUserIdsExcept(excludeUserId);
    await _broadcastToUsers(
      userIds: userIds,
      docId: 'news_$newsId',
      payload: {
        'type': 'news_published',
        'newsId': newsId,
        'title': 'New news posted',
        'body': '"$displayTitle" has been published. Tap to read.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      },
    );
  }

  /// Notifies every user except [excludeUserId] when an event is first created.
  Future<void> notifyAllUsersNewEvent({
    required String eventId,
    required String title,
    required String excludeUserId,
  }) async {
    if (!_ready || eventId.trim().isEmpty) return;
    final displayTitle = title.trim().isNotEmpty ? title.trim() : 'Event';
    final userIds = await _allUserIdsExcept(excludeUserId);
    await _broadcastToUsers(
      userIds: userIds,
      docId: 'event_$eventId',
      payload: {
        'type': 'event_published',
        'eventId': eventId,
        'title': 'New event announced',
        'body': '"$displayTitle" has been added. Tap for details.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      },
    );
  }

  Future<List<String>> _allUserIdsExcept(String excludeUserId) async {
    final snap = await _firestore.collection('users').get();
    final exclude = excludeUserId.trim();
    return snap.docs
        .map((d) => d.id)
        .where((id) => id.isNotEmpty && id != exclude)
        .toList();
  }

  Future<void> _broadcastToUsers({
    required List<String> userIds,
    required String docId,
    required Map<String, dynamic> payload,
  }) async {
    if (userIds.isEmpty) return;
    const chunkSize = 500;
    for (var i = 0; i < userIds.length; i += chunkSize) {
      final end = (i + chunkSize < userIds.length)
          ? i + chunkSize
          : userIds.length;
      final batch = _firestore.batch();
      for (final userId in userIds.sublist(i, end)) {
        batch.set(_col(userId).doc(docId), payload, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    if (!_ready || userId.isEmpty || notificationId.trim().isEmpty) return;
    await _col(
      userId,
    ).doc(notificationId).set({'read': true}, SetOptions(merge: true));
  }

  Stream<List<UserNotificationDoc>> streamForUser(
    String userId, {
    int limit = 40,
  }) {
    if (!_ready || userId.isEmpty) return Stream.value(const []);
    return _col(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map(UserNotificationDoc.fromFirestore).toList(),
        );
  }

  Stream<int> streamUnreadCountForUser(String userId) {
    if (!_ready || userId.isEmpty) return Stream.value(0);
    return _col(userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
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
    this.newsId,
    this.eventId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String type;
  final String? sabaqId;
  final String? newsId;
  final String? eventId;

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
      newsId: d['newsId'] as String?,
      eventId: d['eventId'] as String?,
    );
  }
}
