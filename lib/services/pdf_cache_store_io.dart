import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'pdf_cache_store.dart';

class _IoPdfCacheStore implements PdfCacheStore {
  static const _subDir = 'book_pdfs';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_subDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _fileFor(String bookId) async {
    final dir = await _dir();
    return File('${dir.path}/$bookId.pdf');
  }

  @override
  Future<void> delete(String bookId) async {
    final file = await _fileFor(bookId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> exists(String bookId) async {
    final file = await _fileFor(bookId);
    return file.existsSync() && file.lengthSync() > 0;
  }

  @override
  Future<Uint8List?> load(String bookId) async {
    final file = await _fileFor(bookId);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    return bytes;
  }

  @override
  Future<void> save(String bookId, Uint8List bytes) async {
    final file = await _fileFor(bookId);
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<int> totalBytes() async {
    final dir = await _dir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}

PdfCacheStore createPdfCacheStore() => _IoPdfCacheStore();
