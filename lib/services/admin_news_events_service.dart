import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/event_firestore_model.dart';
import '../models/news_firestore_model.dart';
import 'user_notifications_service.dart';

class AdminNewsEventsService {
  AdminNewsEventsService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Stream<List<NewsFirestoreModel>> streamAllNews() {
    return _firestore.collection('news').snapshots().map((snap) {
      final list = snap.docs.map(NewsFirestoreModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<EventFirestoreModel>> streamAllEvents() {
    return _firestore.collection('events').snapshots().map((snap) {
      final list = snap.docs.map(EventFirestoreModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  String newNewsId() => _firestore.collection('news').doc().id;
  String newEventId() => _firestore.collection('events').doc().id;

  Future<String?> uploadNewsImage({
    required String newsId,
    required String imagePath,
  }) async {
    final file = File(imagePath);
    final lower = imagePath.toLowerCase();
    final ext = lower.endsWith('.png')
        ? 'png'
        : (lower.endsWith('.webp') ? 'webp' : 'jpg');
    final ref = _storage.ref().child('news_images/$newsId.$ext');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String?> uploadEventImage({
    required String eventId,
    required String imagePath,
  }) async {
    final file = File(imagePath);
    final lower = imagePath.toLowerCase();
    final ext = lower.endsWith('.png')
        ? 'png'
        : (lower.endsWith('.webp') ? 'webp' : 'jpg');
    final ref = _storage.ref().child('event_images/$eventId.$ext');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> upsertNews(NewsFirestoreModel model) async {
    await _firestore.collection('news').doc(model.id).set(model.toMap());
  }

  Future<void> createNews(
    NewsFirestoreModel model, {
    required String creatorUserId,
  }) async {
    await upsertNews(model);
    try {
      await UserNotificationsService().notifyAllUsersNewNews(
        newsId: model.id,
        title: model.title,
        excludeUserId: creatorUserId,
      );
    } catch (_) {
      // Notification fan-out is best-effort (rules / offline).
    }
  }

  Future<void> upsertEvent(EventFirestoreModel model) async {
    await _firestore.collection('events').doc(model.id).set(model.toMap());
  }

  Future<void> createEvent(
    EventFirestoreModel model, {
    required String creatorUserId,
  }) async {
    await upsertEvent(model);
    try {
      await UserNotificationsService().notifyAllUsersNewEvent(
        eventId: model.id,
        title: model.title,
        excludeUserId: creatorUserId,
      );
    } catch (_) {
      // Notification fan-out is best-effort (rules / offline).
    }
  }

  Future<void> setNewsActive(String id, bool active) async {
    await _firestore.collection('news').doc(id).update({'isActive': active});
  }

  Future<void> setEventActive(String id, bool active) async {
    await _firestore.collection('events').doc(id).update({'isActive': active});
  }
}

