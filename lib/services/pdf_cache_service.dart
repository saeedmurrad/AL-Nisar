import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Local PDF cache under app documents; filenames `{bookId}.pdf`.
class PdfCacheService {
  static const _subDir = 'book_pdfs';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/$_subDir');
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return d;
  }

  Future<File> _fileFor(String bookId) async {
    final d = await _dir();
    return File('${d.path}/$bookId.pdf');
  }

  Future<File> cacheLocalPdfFromPath(String bookId, String sourcePath) async {
    final src = File(sourcePath);
    if (!await src.exists() || await src.length() == 0) {
      throw Exception('source_missing');
    }
    final out = await _fileFor(bookId);
    if (await out.exists()) {
      await out.delete();
    }
    return src.copy(out.path);
  }

  Future<File> downloadAndCachePdf(
    String bookId,
    String downloadUrl,
    void Function(double progress) onProgress, {
    bool Function()? shouldContinue,
  }) async {
    final out = await _fileFor(bookId);
    final uri = Uri.parse(downloadUrl);
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('Download failed', uri: uri);
      }
      final total = response.contentLength;
      var received = 0;
      final sink = out.openWrite();
      await for (final chunk in response) {
        if (shouldContinue != null && !shouldContinue()) {
          await sink.close();
          if (await out.exists()) await out.delete();
          throw Exception('cancelled');
        }
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) {
          onProgress(received / total);
        } else {
          onProgress(0.5);
        }
      }
      await sink.close();
      onProgress(1.0);
      return out;
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> isPdfCached(String bookId) async {
    final f = await _fileFor(bookId);
    return f.existsSync() && f.lengthSync() > 0;
  }

  Future<File?> getCachedPdf(String bookId) async {
    final f = await _fileFor(bookId);
    if (await f.exists() && await f.length() > 0) return f;
    return null;
  }

  Future<void> deleteCachedPdf(String bookId) async {
    final f = await _fileFor(bookId);
    if (await f.exists()) await f.delete();
  }

  Future<String> getCacheSize() async {
    final d = await _dir();
    if (!await d.exists()) return '0 B';
    var total = 0;
    await for (final entity in d.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    if (total < 1024) return '$total B';
    if (total < 1024 * 1024) {
      return '${(total / 1024).toStringAsFixed(1)} KB';
    }
    return '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
