import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders a simple branded card (title + page) as PNG and shares via [Share.shareXFiles].
/// Syncfusion Flutter PDF does not expose page rasterization; this matches the share caption UX.
Future<void> sharePageImageCard({
  required String bookTitle,
  required int pageNumber,
  required Color accentGold,
  required Color backgroundColor,
  required Color textColor,
}) async {
  const w = 1080.0;
  const h = 1400.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, w, h),
    Paint()..color = backgroundColor,
  );
  final border = Paint()
    ..color = accentGold
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(36, 36, w - 72, h - 72),
      const Radius.circular(20),
    ),
    border,
  );
  final titlePainter = TextPainter(
    text: TextSpan(
      text: bookTitle,
      style: TextStyle(
        color: textColor,
        fontSize: 40,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 4,
    ellipsis: '…',
  )..layout(maxWidth: w - 160);
  titlePainter.paint(canvas, const Offset(80, 100));
  final pagePainter = TextPainter(
    text: TextSpan(
      text: 'Page $pageNumber',
      style: TextStyle(
        color: accentGold,
        fontSize: 52,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  pagePainter.paint(
    canvas,
    Offset(80, 120 + titlePainter.height),
  );
  final sub = TextPainter(
    text: TextSpan(
      text: 'Al Nisar App',
      style: TextStyle(
        color: textColor.withValues(alpha: 0.75),
        fontSize: 28,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  sub.paint(canvas, Offset(80, h - 120));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w.toInt(), h.toInt());
  final bd = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bd == null) return;
  final bytes = bd.buffer.asUint8List();
  final dir = await getTemporaryDirectory();
  final f = File(
    '${dir.path}/al_nisar_page_${pageNumber}_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await f.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(f.path)],
    text: 'From "$bookTitle" — Page $pageNumber\nAl Nisar App',
  );
}
