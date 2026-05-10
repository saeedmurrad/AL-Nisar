import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/asbaq_pdf_model.dart';

class AsbaqService {
  AsbaqService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Stream<List<AsbaqPdfModel>> streamAsbaqPdfs() {
    if (!_firebaseReady) return Stream.value(const []);
    return _firestore.collection('asbaq_pdfs').snapshots().map((snap) {
      final list = snap.docs
          .map(AsbaqPdfModel.fromFirestore)
          .where((d) => d.isActive)
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }
}

