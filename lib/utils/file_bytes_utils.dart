import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

Future<Uint8List?> downloadUrlBytes(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final response = await http.get(uri);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    return null;
  }
  return response.bodyBytes;
}

String imageExtensionFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'png';
  if (lower.endsWith('.webp')) return 'webp';
  return 'jpg';
}

String imageMimeTypeFromName(String name) {
  final ext = imageExtensionFromName(name);
  return ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
}

String pdfMimeType = 'application/pdf';

XFile xFileFromBytes(
  Uint8List bytes, {
  required String name,
  required String mimeType,
}) {
  return XFile.fromData(bytes, mimeType: mimeType, name: name);
}
