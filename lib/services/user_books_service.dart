import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_book_model.dart';

class UserBooksService {
  static const _key = 'user_books_v1';

  Future<List<UserBookModel>> getBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => UserBookModel.fromJson(Map<String, dynamic>.from(m)))
          .where((b) => b.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsertBook(UserBookModel book) async {
    final list = await getBooks();
    final next = <UserBookModel>[
      book,
      ...list.where((b) => b.id != book.id),
    ];
    await _write(next);
  }

  Future<void> removeBook(String id) async {
    if (id.trim().isEmpty) return;
    final list = await getBooks();
    final next = list.where((b) => b.id != id).toList();
    await _write(next);
  }

  Future<void> _write(List<UserBookModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((b) => b.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}

