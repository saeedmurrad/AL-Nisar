import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/sabaq_pdf_model.dart';
import '../utils/sabaq_order_utils.dart';

class SabaqService {
  SabaqService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Stream<List<SabaqPdfModel>> streamSabaqPdfs() {
    if (!_firebaseReady) return Stream.value(const []);
    return _firestore.collection('sabaq_pdfs').snapshots().map((snap) {
      final list = snap.docs
          .map(SabaqPdfModel.fromFirestore)
          .where((d) => d.isActive)
          .toList();
      return dedupeSabaqList(list);
    });
  }
}
