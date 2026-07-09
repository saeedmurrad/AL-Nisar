import 'dart:typed_data';

import 'pdf_cache_store.dart';

class _UnsupportedPdfCacheStore implements PdfCacheStore {
  @override
  Future<void> delete(String bookId) async {}

  @override
  Future<bool> exists(String bookId) async => false;

  @override
  Future<Uint8List?> load(String bookId) async => null;

  @override
  Future<void> save(String bookId, Uint8List bytes) async {}

  @override
  Future<int> totalBytes() async => 0;
}

PdfCacheStore createPdfCacheStore() => _UnsupportedPdfCacheStore();
