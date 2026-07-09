import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import '../models/irshad_firestore_model.dart';
import '../utils/file_bytes_utils.dart';

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
      final bytes = await _downloadToTemp(url, 'irshad_${ir.id}');
      if (bytes == null) {
        await Share.share('$msg\n\n$url');
        return;
      }
      await Share.shareXFiles([
        xFileFromBytes(
          bytes,
          name: 'irshad_${ir.id}.${_guessImageExt(url)}',
          mimeType: imageMimeTypeFromName(url),
        ),
      ], text: msg);
    } catch (_) {
      await Share.share('$msg\n\n$url');
    }
  }

  Future<Uint8List?> _downloadToTemp(String url, String baseName) async {
    return downloadUrlBytes(url);
  }

  String _guessImageExt(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.webp')) return 'webp';
    return 'jpg';
  }
}
