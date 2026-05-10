import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/irshad_firestore_model.dart';

class AdminIrshadatService {
  AdminIrshadatService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Stream<List<IrshadFirestoreModel>> streamAll(IrshadatLanguage language) {
    return _firestore.collection(language.firestoreCollection).snapshots().map((snap) {
      final list = snap.docs.map(IrshadFirestoreModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> upsert(IrshadatLanguage language, IrshadFirestoreModel model) async {
    await _firestore.collection(language.firestoreCollection).doc(model.id).set(model.toMap());
  }

  Future<void> setActive(IrshadatLanguage language, String id, bool active) async {
    await _firestore
        .collection(language.firestoreCollection)
        .doc(id)
        .update({'isActive': active});
  }

  String newId(IrshadatLanguage language) =>
      _firestore.collection(language.firestoreCollection).doc().id;

  Future<String?> uploadImage({
    required IrshadatLanguage language,
    required String id,
    required String imagePath,
  }) async {
    final lower = imagePath.toLowerCase();
    final ext = lower.endsWith('.png')
        ? 'png'
        : (lower.endsWith('.webp') ? 'webp' : 'jpg');
    final langDir = language == IrshadatLanguage.english ? 'en' : 'ur';
    final ref = _storage.ref().child('irshadat_images/$langDir/$id.$ext');
    await ref.putFile(File(imagePath));
    return ref.getDownloadURL();
  }
}

