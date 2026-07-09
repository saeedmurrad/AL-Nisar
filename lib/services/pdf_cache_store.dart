import 'dart:typed_data';

import 'pdf_cache_store_stub.dart'
    if (dart.library.io) 'pdf_cache_store_io.dart'
    if (dart.library.js_interop) 'pdf_cache_store_web.dart'
    as impl;

abstract class PdfCacheStore {
  Future<Uint8List?> load(String bookId);

  Future<void> save(String bookId, Uint8List bytes);

  Future<bool> exists(String bookId);

  Future<void> delete(String bookId);

  Future<int> totalBytes();
}

PdfCacheStore createPdfCacheStore() => impl.createPdfCacheStore();
