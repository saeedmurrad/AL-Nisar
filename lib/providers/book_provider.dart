import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/book_model.dart';
import '../services/book_service.dart';

class BookProvider extends ChangeNotifier {
  BookProvider({BookService? bookService})
    : _service = bookService ?? BookService() {
    loadBooks();
  }

  final BookService _service;

  List<BookModel> _books = [];
  List<BookModel> _filteredBooks = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  StreamSubscription<List<BookModel>>? _sub;

  List<BookModel> get books => List.unmodifiable(_filteredBooks);
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get categories {
    final set = <String>{};
    for (final b in _books) {
      if (b.category.isNotEmpty) set.add(b.category);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  void loadBooks() {
    _sub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _sub = _service.getBooksStream().listen(
      (list) {
        _books = list;
        _isLoading = false;
        _error = null;
        _applyFilters();
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _error = 'load_failed';
        _books = [];
        _applyFilters();
        notifyListeners();
      },
    );
  }

  void _applyFilters() {
    Iterable<BookModel> it = _books;
    if (_selectedCategory != 'All') {
      it = it.where((b) => b.category == _selectedCategory);
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      it = it.where((b) {
        return b.title.toLowerCase().contains(q) ||
            b.titleUrdu.contains(_searchQuery.trim()) ||
            b.author.toLowerCase().contains(q);
      });
    }
    _filteredBooks = it.toList();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
