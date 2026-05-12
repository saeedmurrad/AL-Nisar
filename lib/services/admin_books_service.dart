import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/book_model.dart';

class AdminBooksService {
  AdminBooksService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Reference bookPdfRef(String bookId) => _storage.ref().child('books/$bookId.pdf');
  Reference bookCoverRef(String bookId, {required String extension}) =>
      _storage.ref().child('book_covers/$bookId.$extension');

  UploadTask uploadBookPdfTask({
    required String bookId,
    required String pdfPath,
  }) {
    final file = File(pdfPath);
    final ref = bookPdfRef(bookId);
    return ref.putFile(file, SettableMetadata(contentType: 'application/pdf'));
  }

  Future<String> uploadBookPdf({
    required String bookId,
    required String pdfPath,
  }) async {
    final ref = bookPdfRef(bookId);
    await uploadBookPdfTask(bookId: bookId, pdfPath: pdfPath);
    return ref.fullPath;
  }

  UploadTask uploadCoverPngDataTask({
    required String bookId,
    required Uint8List pngBytes,
  }) {
    final ref = bookCoverRef(bookId, extension: 'png');
    return ref.putData(pngBytes, SettableMetadata(contentType: 'image/png'));
  }

  UploadTask uploadCoverImageTask({
    required String bookId,
    required String imagePath,
  }) {
    final file = File(imagePath);
    final lower = imagePath.toLowerCase();
    final ext = lower.endsWith('.png') ? 'png' : 'jpg';
    final ref = bookCoverRef(bookId, extension: ext);
    return ref.putFile(file);
  }

  Future<String?> uploadCoverImage({
    required String bookId,
    required String imagePath,
  }) async {
    final lower = imagePath.toLowerCase();
    final ext = lower.endsWith('.png') ? 'png' : 'jpg';
    final ref = bookCoverRef(bookId, extension: ext);
    await uploadCoverImageTask(bookId: bookId, imagePath: imagePath);
    return ref.getDownloadURL();
  }

  Future<void> saveBookMetadata(BookModel model) async {
    await _firestore.collection('books').doc(model.id).set(model.toMap());
  }

  Future<String> createNewBookId() async {
    return _firestore.collection('books').doc().id;
  }

  Stream<List<BookModel>> streamAllBooks() {
    return _firestore.collection('books').snapshots().map((snapshot) {
      final list =
          snapshot.docs.map((d) => BookModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  /// Removes the Firestore doc and best-effort deletes PDF and cover in Storage.
  /// Tuple entries are `true` when that object was absent or deleted successfully.
  Future<({bool pdfOk, bool coverOk})> deleteBook(BookModel book) async {
    var pdfOk = true;
    var coverOk = true;
    final sp = book.storagePath.trim();
    if (sp.isNotEmpty) {
      try {
        await _storage.ref(sp).delete();
      } catch (_) {
        pdfOk = false;
      }
    }
    final cu = book.coverImageUrl.trim();
    if (cu.isNotEmpty) {
      try {
        await _storage.refFromURL(cu).delete();
      } catch (_) {
        coverOk = false;
      }
    }
    await _firestore.collection('books').doc(book.id).delete();
    return (pdfOk: pdfOk, coverOk: coverOk);
  }
}

