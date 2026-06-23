import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/irshad_firestore_model.dart';

class IrshadShareService {
  Future<void> share({
    required IrshadFirestoreModel ir,
    required IrshadatLanguage language,
    String? dateLabelOverride,
    bool irshadPakOfTheDay = false,
  }) async {
    final text = ir.text.trim();
    final url = ir.imageUrl.trim();
    final dateLabel = dateLabelOverride ?? ir.dateLabel;
    final heading = irshadPakOfTheDay
        ? 'Irshad Pak of the Day (${language.label}) — $dateLabel'
        : 'Irshad (${language.label}) — $dateLabel';
    final msg = [
      heading,
      if (text.isNotEmpty) text,
      'AL Nisar App',
    ].join('\n\n');

    if (url.isEmpty) {
      await Share.share(msg);
      return;
    }

    try {
      final f = await _downloadToTemp(url, 'irshad_${ir.id}');
      if (f == null) {
        await Share.share('$msg\n\n$url');
        return;
      }
      await Share.shareXFiles([XFile(f.path)], text: msg);
    } catch (_) {
      await Share.share('$msg\n\n$url');
    }
  }

  Future<File?> _downloadToTemp(String url, String baseName) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final dir = await getTemporaryDirectory();
    final ext = _guessImageExt(uri.path);
    final out = File('${dir.path}/$baseName.$ext');

    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final bytes = await consolidateHttpClientResponseBytes(res);
      await out.writeAsBytes(bytes, flush: true);
      return out;
    } finally {
      client.close(force: true);
    }
  }

  String _guessImageExt(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.webp')) return 'webp';
    return 'jpg';
  }
}
