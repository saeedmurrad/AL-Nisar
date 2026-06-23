import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/gallery_folder.dart';
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
          .where((e) => e.showInGallery)
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  static Map<GalleryFolder, List<GalleryImageModel>> groupByFolder(
    List<GalleryImageModel> images,
  ) {
    final map = <GalleryFolder, List<GalleryImageModel>>{};
    for (final folder in GalleryFolder.visibleInGallery) {
      map[folder] = [];
    }
    for (final img in images) {
      final f = img.folderInfo;
      map.putIfAbsent(f, () => []).add(img);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    }
    return map;
  }

  static List<GalleryImageModel> imagesInFolder(
    List<GalleryImageModel> images,
    GalleryFolder folder,
  ) {
    return images
        .where((e) => e.folderInfo.id == folder.id)
        .toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }
}
