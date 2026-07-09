import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/lesson_model.dart';

class LessonsService {
  LessonsService({FirebaseFirestore? firestore, required this.collectionPath})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String collectionPath;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Stream<List<LessonModel>> streamLessons() {
    if (!_firebaseReady) return Stream.value(const []);
    return _firestore.collection(collectionPath).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => LessonModel.fromFirestore(d))
          .where((d) => d.isActive)
          .toList();
      list.sort((a, b) {
        final an = a.lessonNumber ?? 1 << 30;
        final bn = b.lessonNumber ?? 1 << 30;
        if (an != bn) return an.compareTo(bn);
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }
}
