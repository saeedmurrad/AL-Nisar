import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lesson_model.dart';

class AdminLessonsService {
  AdminLessonsService({
    FirebaseFirestore? firestore,
    required this.collectionPath,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String collectionPath;

  Stream<List<LessonModel>> streamAll() {
    return _firestore.collection(collectionPath).snapshots().map((snap) {
      final list = snap.docs.map(LessonModel.fromFirestore).toList();
      list.sort((a, b) {
        final an = a.lessonNumber ?? 1 << 30;
        final bn = b.lessonNumber ?? 1 << 30;
        if (an != bn) return an.compareTo(bn);
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Future<void> upsert(LessonModel model) async {
    await _firestore
        .collection(collectionPath)
        .doc(model.id)
        .set(model.toMap());
  }

  Future<void> setLocked(String id, bool locked) async {
    await _firestore.collection(collectionPath).doc(id).update({
      'isLocked': locked,
    });
  }

  Future<void> setActive(String id, bool active) async {
    await _firestore.collection(collectionPath).doc(id).update({
      'isActive': active,
    });
  }

  String newId() => _firestore.collection(collectionPath).doc().id;
}
