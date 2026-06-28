import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/book_model.dart';

class BookService {
  BookService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Stream<List<BookModel>> getBooksStream() {
    if (!_firebaseReady) {
      return Stream.value(<BookModel>[]);
    }
    return _firestore.collection('books').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((d) => BookModel.fromFirestore(d))
          .where((b) => b.isActive)
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  Future<String> getBookDownloadUrl(String storagePath) async {
    if (!_firebaseReady) {
      throw StateError('Firebase is not initialized');
    }
    final ref = _storage.ref().child(storagePath);
    return ref.getDownloadURL();
  }

  Stream<List<BookModel>> getBooksByCategory(String category) {
    if (!_firebaseReady) {
      return Stream.value(<BookModel>[]);
    }
    if (category == 'All') {
      return getBooksStream();
    }
    return _firestore
        .collection('books')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((d) => BookModel.fromFirestore(d))
          .where((b) => b.isActive)
          .toList();
    });
  }

  Future<List<BookModel>> searchBooks(String query) async {
    if (!_firebaseReady) {
      return [];
    }
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      final snap = await _firestore.collection('books').get();
      return snap.docs
          .map(BookModel.fromFirestore)
          .where((b) => b.isActive)
          .toList();
    }
    final snap = await _firestore.collection('books').get();
    final all = snap.docs
        .map(BookModel.fromFirestore)
        .where((b) => b.isActive)
        .toList();
    return all.where((b) {
      return b.title.toLowerCase().contains(q) ||
          b.titleUrdu.contains(query.trim()) ||
          b.author.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q);
    }).toList();
  }

  Future<BookModel?> getBookById(String id) async {
    if (!_firebaseReady || id.isEmpty) return null;
    final doc = await _firestore.collection('books').doc(id).get();
    if (!doc.exists) return null;
    return BookModel.fromFirestore(doc);
  }
}
