import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/event_firestore_model.dart';
import '../models/news_firestore_model.dart';

class NewsEventsService {
  NewsEventsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  Stream<List<NewsFirestoreModel>> streamNews() {
    if (!isFirebaseReady) return Stream.value(const []);
    return _firestore.collection('news').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => NewsFirestoreModel.fromFirestore(d))
          .where((d) => d.isActive)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((_) => <NewsFirestoreModel>[]);
  }

  Stream<List<EventFirestoreModel>> streamEvents() {
    if (!isFirebaseReady) return Stream.value(const []);
    return _firestore.collection('events').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => EventFirestoreModel.fromFirestore(d))
          .where((d) => d.isActive)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((_) => <EventFirestoreModel>[]);
  }

  Future<NewsFirestoreModel?> getNewsById(String id) async {
    if (!isFirebaseReady || id.trim().isEmpty) return null;
    final doc = await _firestore.collection('news').doc(id).get();
    if (!doc.exists) return null;
    return NewsFirestoreModel.fromFirestore(doc);
  }

  Future<EventFirestoreModel?> getEventById(String id) async {
    if (!isFirebaseReady || id.trim().isEmpty) return null;
    final doc = await _firestore.collection('events').doc(id).get();
    if (!doc.exists) return null;
    return EventFirestoreModel.fromFirestore(doc);
  }
}

