import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/sabaq_pdf_model.dart';

class AdminSabaqService {
  AdminSabaqService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection('sabaq_pdfs');

  Reference pdfRef(String id) => _storage.ref().child('sabaq_pdfs/$id.pdf');

  Reference thumbRef(String id, {required String extension}) =>
      _storage.ref().child('sabaq_thumbs/$id.$extension');

  String newId() => _col.doc().id;

  UploadTask uploadPdfTask({required String id, required String pdfPath}) {
    return pdfRef(id).putFile(
      File(pdfPath),
      SettableMetadata(contentType: 'application/pdf'),
    );
  }

  UploadTask uploadThumbTask({required String id, required String imagePath}) {
    final lower = imagePath.toLowerCase();
    final ext = lower.endsWith('.png') ? 'png' : 'jpg';
    return thumbRef(id, extension: ext).putFile(File(imagePath));
  }

  Future<String> getThumbUrl({required String id, required String imagePath}) async {
    final lower = imagePath.toLowerCase();
    final ext = lower.endsWith('.png') ? 'png' : 'jpg';
    return thumbRef(id, extension: ext).getDownloadURL();
  }

  Future<void> upsert(SabaqPdfModel model) async {
    await _col.doc(model.id).set(model.toMap());
  }
}
