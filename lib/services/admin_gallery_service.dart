import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/gallery_folder.dart';
import '../models/gallery_image_model.dart';

class AdminGalleryService {
  AdminGalleryService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('gallery_images');

  String newId() => _col.doc().id;

  Reference imageRef(String id, {required String extension}) =>
      _storage.ref().child('gallery_images/$id.$extension');

  UploadTask uploadImageTask({
    required String id,
    required String extension,
    required String imagePath,
  }) {
    return imageRef(id, extension: extension).putFile(
      File(imagePath),
      SettableMetadata(contentType: 'image/$extension'),
    );
  }

  Future<String> getDownloadUrl(String id, {required String extension}) async {
    return imageRef(id, extension: extension).getDownloadURL();
  }

  Future<void> updateFolder(String id, String folderId) async {
    await _col.doc(id).set(
      {'folder': GalleryFolder.normalizeId(folderId)},
      SetOptions(merge: true),
    );
  }

  Future<void> upsert(GalleryImageModel model) async {
    await _col.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  Stream<List<GalleryImageModel>> streamAll() {
    return _col.snapshots().map((snap) {
      final list =
          snap.docs.map((d) => GalleryImageModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  /// Deletes Firestore metadata. Deletes Storage when [item.storagePath] is set.
  /// Returns `false` if Storage deletion failed (file missing or rules); Firestore is still removed.
  Future<bool> deleteGalleryImage(GalleryImageModel item) async {
    var storageOk = true;
    final path = item.storagePath.trim();
    if (path.isNotEmpty) {
      try {
        await _storage.ref(path).delete();
      } catch (_) {
        storageOk = false;
      }
    }
    await _col.doc(item.id).delete();
    return storageOk;
  }
}

