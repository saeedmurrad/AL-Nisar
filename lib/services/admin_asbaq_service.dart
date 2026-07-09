import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/asbaq_pdf_model.dart';
import '../models/upload_file_data.dart';
import '../utils/file_bytes_utils.dart';

class AdminAsbaqService {
  AdminAsbaqService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('asbaq_pdfs');

  Reference pdfRef(String id) => _storage.ref().child('asbaq_pdfs/$id.pdf');

  Reference thumbRef(String id, {required String extension}) =>
      _storage.ref().child('asbaq_thumbs/$id.$extension');

  String newId() => _col.doc().id;

  UploadTask uploadPdfTask({required String id, required UploadFileData pdf}) {
    return pdfRef(id).putData(
      pdf.bytes,
      SettableMetadata(
        contentType: pdfMimeType,
        customMetadata: {'originalName': pdf.name},
      ),
    );
  }

  UploadTask uploadThumbTask({
    required String id,
    required UploadFileData image,
  }) {
    final ext = imageExtensionFromName(image.name);
    return thumbRef(id, extension: ext).putData(
      image.bytes,
      SettableMetadata(
        contentType: imageMimeTypeFromName(image.name),
        customMetadata: {'originalName': image.name},
      ),
    );
  }

  Future<String> getThumbUrl({
    required String id,
    required String imageName,
  }) async {
    final ext = imageExtensionFromName(imageName);
    return thumbRef(id, extension: ext).getDownloadURL();
  }

  Future<void> upsert(AsbaqPdfModel model) async {
    await _col.doc(model.id).set(model.toMap());
  }
}
