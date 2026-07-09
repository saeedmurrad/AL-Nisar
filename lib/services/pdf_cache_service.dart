import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'pdf_cache_store.dart';

/// Local PDF cache under app documents; filenames `{bookId}.pdf`.
class PdfCacheService {
  PdfCacheService({PdfCacheStore? store})
    : _store = store ?? createPdfCacheStore();

  final PdfCacheStore _store;

  Future<Uint8List> cachePdfBytes(String bookId, Uint8List bytes) async {
    if (bytes.isEmpty) throw Exception('source_missing');
    await _store.save(bookId, bytes);
    return bytes;
  }

  Future<Uint8List> downloadAndCachePdf(
    String bookId,
    String downloadUrl,
    void Function(double progress) onProgress, {
    bool Function()? shouldContinue,
  }) async {
    final uri = Uri.parse(downloadUrl);
    final request = http.Request('GET', uri);
    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw Exception('download_failed');
      }
      final total = response.contentLength;
      var received = 0;
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.stream) {
        if (shouldContinue != null && !shouldContinue()) {
          throw Exception('cancelled');
        }
        received += chunk.length;
        bytes.add(chunk);
        if (total != null && total > 0) {
          onProgress(received / total);
        } else {
          onProgress(0.5);
        }
      }
      final data = bytes.toBytes();
      await _store.save(bookId, data);
      onProgress(1.0);
      return data;
    } finally {
      client.close();
    }
  }

  Future<bool> isPdfCached(String bookId) async {
    return _store.exists(bookId);
  }

  Future<Uint8List?> getCachedPdfBytes(String bookId) async {
    return _store.load(bookId);
  }

  Future<void> deleteCachedPdf(String bookId) async {
    await _store.delete(bookId);
  }

  Future<String> getCacheSize() async {
    final total = await _store.totalBytes();
    if (total < 1024) return '$total B';
    if (total < 1024 * 1024) {
      return '${(total / 1024).toStringAsFixed(1)} KB';
    }
    return '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
