import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/shajra_urdu_detail_model.dart';

class AdminShajraUrduService {
  AdminShajraUrduService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('shajra_urdu_details');

  Reference pdfRef(int number) => _storage.ref().child('shajra_urdu/$number.pdf');

  UploadTask uploadPdfTask({
    required int number,
    required String pdfPath,
  }) {
    final file = File(pdfPath);
    return pdfRef(number).putFile(
      file,
      SettableMetadata(contentType: 'application/pdf'),
    );
  }

  Future<void> upsertDetail(ShajraUrduDetailModel model) async {
    await _col.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }
}

