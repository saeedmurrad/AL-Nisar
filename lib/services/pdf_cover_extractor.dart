import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Reads page count and optionally rasterizes the first page for a cover thumbnail.
///
/// Uses [pdfx] on supported IO platforms (Android, iOS, macOS, Windows). On Web,
/// Linux, or if rendering fails, page count falls back to Syncfusion (no thumbnail).
Future<({int pageCount, Uint8List? coverPng})> extractPdfPageCountAndCover(
  Uint8List pdfBytes, {
  String? pdfPath,
}) async {
  if (pdfBytes.isEmpty) {
    return (pageCount: 0, coverPng: null);
  }

  if (!kIsWeb && pdfPath != null && await hasPdfSupport()) {
    PdfDocument? pdfxDoc;
    try {
      pdfxDoc = await PdfDocument.openFile(pdfPath);
      final n = pdfxDoc.pagesCount;
      Uint8List? cover;
      if (n >= 1) {
        final page = await pdfxDoc.getPage(1);
        try {
          cover = await _renderFirstPageCover(page);
        } finally {
          await page.close();
        }
      }
      await pdfxDoc.close();
      pdfxDoc = null;
      if (n > 0) {
        return (pageCount: n, coverPng: cover);
      }
    } catch (_) {
      try {
        await pdfxDoc?.close();
      } catch (_) {}
    }
  }

  return _pageCountSyncfusionOnly(pdfBytes);
}

Future<Uint8List?> _renderFirstPageCover(PdfPage page) async {
  final pw = page.width;
  final ph = page.height;
  if (pw <= 0 || ph <= 0) return null;

  const maxSide = 900.0;
  double rw = pw;
  double rh = ph;
  if (pw >= ph) {
    if (pw > maxSide) {
      rw = maxSide;
      rh = ph * maxSide / pw;
    }
  } else {
    if (ph > maxSide) {
      rh = maxSide;
      rw = pw * maxSide / ph;
    }
  }

  final img = await page.render(
    width: rw,
    height: rh,
    format: PdfPageImageFormat.png,
    backgroundColor: '#FFFFFF',
  );
  return img?.bytes;
}

Future<({int pageCount, Uint8List? coverPng})> _pageCountSyncfusionOnly(
  Uint8List pdfBytes,
) async {
  sf.PdfDocument? doc;
  try {
    doc = sf.PdfDocument(inputBytes: pdfBytes);
    final n = doc.pages.count;
    return (pageCount: n > 0 ? n : 0, coverPng: null);
  } catch (_) {
    return (pageCount: 0, coverPng: null);
  } finally {
    doc?.dispose();
  }
}
