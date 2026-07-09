import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/irshad_firestore_model.dart';
import '../models/upload_file_data.dart';
import '../utils/file_bytes_utils.dart';

class AdminIrshadatService {
  AdminIrshadatService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Stream<List<IrshadFirestoreModel>> streamAll(IrshadatLanguage language) {
    return _firestore.collection(language.firestoreCollection).snapshots().map((
      snap,
    ) {
      final list = snap.docs.map(IrshadFirestoreModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> upsert(
    IrshadatLanguage language,
    IrshadFirestoreModel model,
  ) async {
    await _firestore
        .collection(language.firestoreCollection)
        .doc(model.id)
        .set(model.toMap());
  }

  Future<void> setActive(
    IrshadatLanguage language,
    String id,
    bool active,
  ) async {
    await _firestore.collection(language.firestoreCollection).doc(id).update({
      'isActive': active,
    });
  }

  String newId(IrshadatLanguage language) =>
      _firestore.collection(language.firestoreCollection).doc().id;

  Future<String?> uploadImage({
    required IrshadatLanguage language,
    required String id,
    required UploadFileData image,
  }) async {
    final ext = imageExtensionFromName(image.name);
    final langDir = language == IrshadatLanguage.english ? 'en' : 'ur';
    final ref = _storage.ref().child('irshadat_images/$langDir/$id.$ext');
    await ref.putData(
      image.bytes,
      SettableMetadata(
        contentType: imageMimeTypeFromName(image.name),
        customMetadata: {'originalName': image.name},
      ),
    );
    return ref.getDownloadURL();
  }

  /// Deletes the Firestore doc and best-effort deletes the image in Storage.
  /// Returns `false` if Storage deletion failed; metadata is still removed.
  Future<bool> deleteIrshad(
    IrshadatLanguage language,
    IrshadFirestoreModel model,
  ) async {
    var storageOk = true;
    final url = model.imageUrl.trim();
    if (url.isNotEmpty) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {
        storageOk = false;
      }
    }
    await _firestore
        .collection(language.firestoreCollection)
        .doc(model.id)
        .delete();
    return storageOk;
  }
}
