import 'dart:math' as math;

import 'package:flutter/material.dart';

enum HomeGridIconKind {
  asbaqTareeqat,
  books,
  irshadat,
  newsEvents,
  shijraPak,
  gallery,
}

class HomeGridIcon extends StatelessWidget {
  const HomeGridIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = 44,
  });

  final HomeGridIconKind kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HomeGridIconPainter(kind: kind, color: color),
    );
  }
}

class _HomeGridIconPainter extends CustomPainter {
  _HomeGridIconPainter({required this.kind, required this.color});

  final HomeGridIconKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.045)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final s = size.shortestSide;
    final pad = s * 0.08;
    final r = Rect.fromLTWH(pad, pad, size.width - pad * 2, size.height - pad * 2);

    switch (kind) {
      case HomeGridIconKind.asbaqTareeqat:
        _openBook(canvas, r, stroke);
        break;
      case HomeGridIconKind.books:
        _stackedBooks(canvas, r, stroke);
        break;
      case HomeGridIconKind.irshadat:
        _heart(canvas, r, stroke);
        break;
      case HomeGridIconKind.newsEvents:
        _calendarStar(canvas, r, stroke, fill);
        break;
      case HomeGridIconKind.shijraPak:
        _silsilaTree(canvas, r, stroke);
        break;
      case HomeGridIconKind.gallery:
        _fourSquares(canvas, r, stroke);
        break;
    }
  }

  void _openBook(Canvas canvas, Rect r, Paint stroke) {
    final mid = r.center.dx;
    final top = r.top + r.height * 0.12;
    final bottom = r.bottom - r.height * 0.12;
    final w = r.width * 0.42;
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(mid - w, top, w, bottom - top),
      const Radius.circular(3),
    );
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(mid, top, w, bottom - top),
      const Radius.circular(3),
    );
    canvas.drawRRect(leftRect, stroke);
    canvas.drawRRect(rightRect, stroke);
    canvas.drawLine(Offset(mid, top), Offset(mid, bottom), stroke);
  }

  void _stackedBooks(Canvas canvas, Rect r, Paint stroke) {
    final h = r.height * 0.38;
    final w = r.width * 0.88;
    final x0 = r.left + r.width * 0.06;
    final y0 = r.top + r.height * 0.12;
    final y1 = y0 + h * 0.55;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(x0, y0, w, h),
      const Radius.circular(3),
    );
    final rr2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(x0 + r.width * 0.08, y1, w * 0.92, h),
      const Radius.circular(3),
    );
    canvas.drawRRect(rr2, stroke);
    canvas.drawRRect(rr, stroke);
  }

  void _heart(Canvas canvas, Rect r, Paint stroke) {
    final cx = r.center.dx;
    final cy = r.center.dy + r.height * 0.04;
    final scale = r.shortestSide * 0.22;
    final path = Path();
    path.moveTo(cx, cy + scale * 0.35);
    path.cubicTo(
      cx - scale * 1.2,
      cy - scale * 0.1,
      cx - scale * 1.2,
      cy - scale * 0.95,
      cx,
      cy - scale * 0.55,
    );
    path.cubicTo(
      cx + scale * 1.2,
      cy - scale * 0.95,
      cx + scale * 1.2,
      cy - scale * 0.1,
      cx,
      cy + scale * 0.35,
    );
    path.close();
    canvas.drawPath(path, stroke);
  }

  void _calendarStar(Canvas canvas, Rect r, Paint stroke, Paint fill) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(r.left, r.top + r.height * 0.18, r.width, r.height * 0.72),
      const Radius.circular(4),
    );
    canvas.drawRRect(rr, stroke);
    canvas.drawLine(
      Offset(r.left + r.width * 0.28, r.top + r.height * 0.18),
      Offset(r.left + r.width * 0.28, r.top + r.height * 0.08),
      stroke,
    );
    canvas.drawLine(
      Offset(r.left + r.width * 0.72, r.top + r.height * 0.18),
      Offset(r.left + r.width * 0.72, r.top + r.height * 0.08),
      stroke,
    );
    final cx = r.center.dx;
    final cy = r.top + r.height * 0.56;
    final rs = r.shortestSide * 0.11;
    _drawStar(canvas, Offset(cx, cy), rs, fill, stroke);
  }

  void _drawStar(Canvas canvas, Offset c, double radius, Paint fill, Paint stroke) {
    const points = 5;
    final inner = radius * 0.45;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final rad = (math.pi / points) * i - math.pi / 2;
      final rr = i.isEven ? radius : inner;
      final x = c.dx + math.cos(rad) * rr;
      final y = c.dy + math.sin(rad) * rr;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _silsilaTree(Canvas canvas, Rect r, Paint stroke) {
    final base = Offset(r.center.dx, r.bottom - r.height * 0.12);
    canvas.drawLine(base, Offset(r.center.dx, r.top + r.height * 0.35), stroke);
    canvas.drawLine(
      Offset(r.center.dx, r.top + r.height * 0.5),
      Offset(r.left + r.width * 0.2, r.top + r.height * 0.35),
      stroke,
    );
    canvas.drawLine(
      Offset(r.center.dx, r.top + r.height * 0.42),
      Offset(r.right - r.width * 0.2, r.top + r.height * 0.28),
      stroke,
    );
    canvas.drawLine(
      Offset(r.center.dx, r.top + r.height * 0.58),
      Offset(r.left + r.width * 0.25, r.top + r.height * 0.72),
      stroke,
    );
    canvas.drawLine(
      Offset(r.center.dx, r.top + r.height * 0.58),
      Offset(r.right - r.width * 0.25, r.top + r.height * 0.72),
      stroke,
    );
    canvas.drawCircle(Offset(r.left + r.width * 0.2, r.top + r.height * 0.35), 3, stroke);
    canvas.drawCircle(Offset(r.right - r.width * 0.2, r.top + r.height * 0.28), 3, stroke);
    canvas.drawCircle(Offset(r.left + r.width * 0.25, r.top + r.height * 0.72), 3, stroke);
    canvas.drawCircle(Offset(r.right - r.width * 0.25, r.top + r.height * 0.72), 3, stroke);
  }

  void _fourSquares(Canvas canvas, Rect r, Paint stroke) {
    final gap = r.shortestSide * 0.1;
    final cellW = (r.width - gap) / 2;
    final cellH = (r.height - gap) / 2;
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 2; col++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.left + col * (cellW + gap),
            r.top + row * (cellH + gap),
            cellW,
            cellH,
          ),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HomeGridIconPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.color != color;
  }
}
