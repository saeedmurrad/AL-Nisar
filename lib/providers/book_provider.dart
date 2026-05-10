import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/book_model.dart';
import '../models/user_book_model.dart';
import '../services/book_service.dart';
import '../services/user_books_service.dart';

class BookProvider extends ChangeNotifier {
  BookProvider({
    BookService? bookService,
    UserBooksService? userBooksService,
  })  : _service = bookService ?? BookService(),
        _userBooksService = userBooksService ?? UserBooksService() {
    _loadUserBooks();
    loadBooks();
  }

  final BookService _service;
  final UserBooksService _userBooksService;

  List<BookModel> _books = [];
  List<BookModel> _userBooks = [];
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
    for (final b in [..._books, ..._userBooks]) {
      if (b.category.isNotEmpty) set.add(b.category);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  Future<void> reloadUserBooks() async {
    await _loadUserBooks();
    _applyFilters();
    notifyListeners();
  }

  Future<void> _loadUserBooks() async {
    final list = await _userBooksService.getBooks();
    _userBooks = list.map(_toBookModel).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    _applyFilters();
    notifyListeners();
  }

  BookModel _toBookModel(UserBookModel b) {
    return BookModel(
      id: b.id,
      title: b.title,
      titleUrdu: b.titleUrdu,
      author: b.author,
      category: b.category.isEmpty ? 'My Books' : b.category,
      description: b.description,
      storagePath: '', // local PDFs are stored in PdfCacheService by id
      coverImageUrl: '',
      totalPages: b.totalPages,
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(
        b.addedAtMs == 0 ? DateTime.now().millisecondsSinceEpoch : b.addedAtMs,
      ),
      isActive: true,
    );
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

        // If Firestore is empty, fall back to listing PDFs in Storage `books/`.
        if (list.isEmpty) {
          _loadFallbackFromStorage();
        }
      },
      onError: (_) => _loadFallbackFromStorage(onFailureSetError: true),
    );
  }

  Future<void> _loadFallbackFromStorage({bool onFailureSetError = false}) async {
    try {
      final storageBooks = await _service.listBooksFromStorage();
      if (storageBooks.isEmpty) {
        if (onFailureSetError) {
          _isLoading = false;
          _error = 'load_failed';
          _books = [];
          _applyFilters();
          notifyListeners();
        }
        return;
      }
      _books = storageBooks;
      _isLoading = false;
      _error = null;
      _applyFilters();
      notifyListeners();
    } catch (_) {
      if (onFailureSetError) {
        _isLoading = false;
        _error = 'load_failed';
        _books = [];
        _applyFilters();
        notifyListeners();
      }
    }
  }

  void _applyFilters() {
    Iterable<BookModel> it = [..._userBooks, ..._books];
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
