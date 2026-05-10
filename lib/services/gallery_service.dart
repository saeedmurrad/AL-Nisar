import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/gallery_image_model.dart';

class GalleryService {
  GalleryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('gallery_images');

  Stream<List<GalleryImageModel>> streamActive() {
    if (!_firebaseReady) return Stream.value(const <GalleryImageModel>[]);
    return _col.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => GalleryImageModel.fromFirestore(d))
          .where((e) => e.isActive && e.downloadUrl.isNotEmpty)
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }
}

