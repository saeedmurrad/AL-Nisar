import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/event_firestore_model.dart';
import '../models/news_firestore_model.dart';

class NewsEventsService {
  NewsEventsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Stream<List<NewsFirestoreModel>> streamNews() {
    if (!_firebaseReady) return Stream.value(const []);
    return _firestore.collection('news').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => NewsFirestoreModel.fromFirestore(d))
          .where((d) => d.isActive)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<EventFirestoreModel>> streamEvents() {
    if (!_firebaseReady) return Stream.value(const []);
    return _firestore.collection('events').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => EventFirestoreModel.fromFirestore(d))
          .where((d) => d.isActive)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<NewsFirestoreModel?> getNewsById(String id) async {
    if (!_firebaseReady || id.trim().isEmpty) return null;
    final doc = await _firestore.collection('news').doc(id).get();
    if (!doc.exists) return null;
    return NewsFirestoreModel.fromFirestore(doc);
  }

  Future<EventFirestoreModel?> getEventById(String id) async {
    if (!_firebaseReady || id.trim().isEmpty) return null;
    final doc = await _firestore.collection('events').doc(id).get();
    if (!doc.exists) return null;
    return EventFirestoreModel.fromFirestore(doc);
  }
}

