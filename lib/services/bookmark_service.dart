import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bookmark_model.dart';

class BookmarkService {
  BookmarkService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _prefsKey = 'al_nisar_bookmarks_v1';

  String _prefsKeyForUser(String? uid) =>
      uid == null || uid.isEmpty ? _prefsKey : '${_prefsKey}_$uid';

  CollectionReference<Map<String, dynamic>>? get _userBookmarksRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return _firestore.collection('users').doc(uid).collection('bookmarks');
  }

  Future<List<BookmarkModel>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyForUser(_auth.currentUser?.uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BookmarkModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<BookmarkModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKeyForUser(_auth.currentUser?.uid), encoded);
  }

  String _storageKey(String bookId, int pageNumber) =>
      'bookmark_${bookId}_$pageNumber';

  Future<void> addBookmark(
    String bookId,
    int pageNumber,
    String note, {
    String bookTitle = '',
    String? bookStoragePath,
  }) async {
    // Firestore (per-user) when authenticated.
    final ref = _userBookmarksRef;
    if (ref != null) {
      final id = _storageKey(bookId, pageNumber);
      await ref.doc(id).set({
        'bookId': bookId,
        'bookTitle': bookTitle,
        'bookStoragePath': bookStoragePath,
        'pageNumber': pageNumber,
        'note': note,
        'savedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final all = await _loadAll();
    all.removeWhere(
      (b) => b.bookId == bookId && b.pageNumber == pageNumber,
    );
    all.add(
      BookmarkModel(
        bookId: bookId,
        bookTitle: bookTitle,
        bookStoragePath: bookStoragePath,
        pageNumber: pageNumber,
        note: note,
        savedAt: DateTime.now(),
      ),
    );
    await _saveAll(all);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(bookId, pageNumber),
      jsonEncode({
        'note': note,
        'savedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<List<BookmarkModel>> getBookmarksForBook(String bookId) async {
    final ref = _userBookmarksRef;
    if (ref != null) {
      final snap = await ref.where('bookId', isEqualTo: bookId).get();
      final list = snap.docs.map((d) => _fromDoc(d.data())).toList()
        ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      return list;
    }
    final all = await _loadAll();
    return all.where((b) => b.bookId == bookId).toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }

  Future<List<BookmarkModel>> getAllBookmarks() async {
    final ref = _userBookmarksRef;
    if (ref != null) {
      final snap = await ref.orderBy('savedAt', descending: true).get();
      return snap.docs.map((d) => _fromDoc(d.data())).toList();
    }
    final all = await _loadAll();
    all.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return all;
  }

  Future<void> removeBookmark(String bookId, int pageNumber) async {
    final ref = _userBookmarksRef;
    if (ref != null) {
      await ref.doc(_storageKey(bookId, pageNumber)).delete();
      return;
    }
    final all = await _loadAll();
    all.removeWhere(
      (b) => b.bookId == bookId && b.pageNumber == pageNumber,
    );
    await _saveAll(all);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(bookId, pageNumber));
  }

  Future<bool> isPageBookmarked(String bookId, int pageNumber) async {
    final ref = _userBookmarksRef;
    if (ref != null) {
      final doc = await ref.doc(_storageKey(bookId, pageNumber)).get();
      return doc.exists;
    }
    final all = await _loadAll();
    return all.any(
      (b) => b.bookId == bookId && b.pageNumber == pageNumber,
    );
  }

  Future<BookmarkModel?> getBookmark(String bookId, int pageNumber) async {
    final ref = _userBookmarksRef;
    if (ref != null) {
      final doc = await ref.doc(_storageKey(bookId, pageNumber)).get();
      if (!doc.exists) return null;
      return _fromDoc(doc.data() ?? {});
    }
    final all = await _loadAll();
    try {
      return all.firstWhere(
        (b) => b.bookId == bookId && b.pageNumber == pageNumber,
      );
    } catch (_) {
      return null;
    }
  }

  /// Total bookmark count and distinct book count for profile summary.
  Future<({int pageCount, int bookCount})> getBookmarkStats() async {
    final ref = _userBookmarksRef;
    if (ref != null) {
      final snap = await ref.get();
      final all = snap.docs.map((d) => _fromDoc(d.data())).toList();
      final ids = all.map((b) => b.bookId).toSet();
      return (pageCount: all.length, bookCount: ids.length);
    }
    final all = await _loadAll();
    final ids = all.map((b) => b.bookId).toSet();
    return (pageCount: all.length, bookCount: ids.length);
  }

  BookmarkModel _fromDoc(Map<String, dynamic> data) {
    DateTime savedAt = DateTime.now();
    final v = data['savedAt'];
    if (v is Timestamp) savedAt = v.toDate();
    return BookmarkModel(
      bookId: data['bookId'] as String? ?? '',
      bookTitle: data['bookTitle'] as String? ?? '',
      bookStoragePath: data['bookStoragePath'] as String?,
      pageNumber: (data['pageNumber'] as num?)?.toInt() ?? 0,
      note: data['note'] as String? ?? '',
      savedAt: savedAt,
    );
  }
}
