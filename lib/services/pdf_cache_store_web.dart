import 'dart:typed_data';

import 'pdf_cache_store.dart';

class _WebPdfCacheStore implements PdfCacheStore {
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  @override
  Future<void> delete(String bookId) async {
    _cache.remove(bookId);
  }

  @override
  Future<bool> exists(String bookId) async {
    return (_cache[bookId]?.isNotEmpty ?? false);
  }

  @override
  Future<Uint8List?> load(String bookId) async {
    return _cache[bookId];
  }

  @override
  Future<void> save(String bookId, Uint8List bytes) async {
    _cache[bookId] = bytes;
  }

  @override
  Future<int> totalBytes() async {
    return _cache.values.fold<int>(0, (sum, bytes) => sum + bytes.length);
  }
}

PdfCacheStore createPdfCacheStore() => _WebPdfCacheStore();
