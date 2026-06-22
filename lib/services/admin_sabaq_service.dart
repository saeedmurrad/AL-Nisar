import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/sabaq_pdf_model.dart';
import '../utils/sabaq_order_utils.dart';

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

  /// Marks older active docs with the same lesson number inactive after re-upload.
  Future<void> deactivateOlderDuplicates(SabaqPdfModel latest) async {
    final order = latest.orderNumber ??
        parseSabaqOrderNumber(latest.titleEn, titleUr: latest.titleUr);
    if (order == null) return;

    final snap = await _col.where('isActive', isEqualTo: true).get();
    final batch = _firestore.batch();
    var writes = 0;

    for (final doc in snap.docs) {
      if (doc.id == latest.id) continue;
      final existing = SabaqPdfModel.fromFirestore(doc);
      final existingOrder = existing.orderNumber ??
          parseSabaqOrderNumber(existing.titleEn, titleUr: existing.titleUr);
      if (existingOrder != order) continue;

      batch.update(doc.reference, {'isActive': false});
      writes++;
      if (writes >= 400) break;
    }

    if (writes > 0) {
      await batch.commit();
    }
  }
}
