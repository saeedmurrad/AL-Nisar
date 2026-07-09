import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/upload_file_data.dart';
import '../models/book_model.dart';
import '../utils/file_bytes_utils.dart';

class AdminBooksService {
  AdminBooksService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Reference bookPdfRef(String bookId) =>
      _storage.ref().child('books/$bookId.pdf');
  Reference bookCoverRef(String bookId, {required String extension}) =>
      _storage.ref().child('book_covers/$bookId.$extension');

  UploadTask uploadBookPdfTask({
    required String bookId,
    required UploadFileData pdf,
  }) {
    final ref = bookPdfRef(bookId);
    return ref.putData(
      pdf.bytes,
      SettableMetadata(
        contentType: pdfMimeType,
        customMetadata: {'originalName': pdf.name},
      ),
    );
  }

  Future<String> uploadBookPdf({
    required String bookId,
    required UploadFileData pdf,
  }) async {
    final ref = bookPdfRef(bookId);
    await uploadBookPdfTask(bookId: bookId, pdf: pdf);
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
    required UploadFileData image,
  }) {
    final ext = imageExtensionFromName(image.name);
    final ref = bookCoverRef(bookId, extension: ext);
    return ref.putData(
      image.bytes,
      SettableMetadata(
        contentType: imageMimeTypeFromName(image.name),
        customMetadata: {'originalName': image.name},
      ),
    );
  }

  Future<String?> uploadCoverImage({
    required String bookId,
    required UploadFileData image,
  }) async {
    final ext = imageExtensionFromName(image.name);
    final ref = bookCoverRef(bookId, extension: ext);
    await uploadCoverImageTask(bookId: bookId, image: image);
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
      final list = snapshot.docs
          .map((d) => BookModel.fromFirestore(d))
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  /// Removes the Firestore doc and best-effort deletes PDF and cover in Storage.
  /// Tuple entries are `true` when that object was absent or deleted successfully.
  Future<({bool pdfOk, bool coverOk})> deleteBook(BookModel book) async {
    var pdfOk = true;
    var coverOk = true;

    final pathsToTry = <String>{
      book.storagePath.trim(),
      bookPdfRef(book.id).fullPath,
    }..removeWhere((p) => p.isEmpty);

    for (final sp in pathsToTry) {
      try {
        await _storage.ref(sp).delete();
      } catch (_) {
        pdfOk = false;
      }
    }

    final hadCover = book.coverImageUrl.trim().isNotEmpty;
    if (hadCover) {
      try {
        await _storage.refFromURL(book.coverImageUrl.trim()).delete();
      } catch (_) {
        coverOk = false;
      }
    }

    for (final ext in const ['png', 'jpg', 'jpeg']) {
      try {
        await bookCoverRef(book.id, extension: ext).delete();
      } catch (_) {
        // Ignore missing cover variants.
      }
    }

    await _firestore.collection('books').doc(book.id).delete();
    if (!hadCover) coverOk = true;
    return (pdfOk: pdfOk, coverOk: coverOk);
  }
}
