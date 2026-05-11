import 'dart:io';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Reads total page count from a PDF file using Syncfusion (pure Dart, no legacy Android embedding).
///
/// [coverPng] is always null here: rasterizing the first page needs a maintained native renderer;
/// admins can still pick an optional cover image in [AdminUploadBookScreen].
Future<({int pageCount, Uint8List? coverPng})> extractPdfPageCountAndCover(
  String pdfPath,
) async {
  if (!File(pdfPath).existsSync()) {
    return (pageCount: 0, coverPng: null);
  }
  PdfDocument? doc;
  try {
    final bytes = await File(pdfPath).readAsBytes();
    doc = PdfDocument(inputBytes: bytes);
    final n = doc.pages.count;
    return (pageCount: n > 0 ? n : 0, coverPng: null);
  } catch (_) {
    return (pageCount: 0, coverPng: null);
  } finally {
    doc?.dispose();
  }
}
