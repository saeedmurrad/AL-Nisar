import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';

/// Gold wifi-off style icon for error / offline states.
class WifiOffGoldIcon extends StatelessWidget {
  const WifiOffGoldIcon({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomPaint(
      size: Size(size, size),
      painter: _WifiOffPainter(color: c.accentGold),
    );
  }
}

class _WifiOffPainter extends CustomPainter {
  _WifiOffPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final r = size.width * 0.22;
    for (int i = 0; i < 3; i++) {
      final rr = r + i * size.width * 0.1;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: rr),
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        stroke,
      );
    }
    final diag = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    final pad = size.width * 0.12;
    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(size.width - pad, pad),
      diag,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Open book icon for empty states.
class OpenBookGoldIcon extends StatelessWidget {
  const OpenBookGoldIcon({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomPaint(
      size: Size(size, size),
      painter: _OpenBookPainter(
        stroke: c.accentGold,
        fill: c.backgroundSurface,
      ),
    );
  }
}

class _OpenBookPainter extends CustomPainter {
  _OpenBookPainter({required this.stroke, required this.fill});

  final Color stroke;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeJoin = StrokeJoin.round;
    final mid = w / 2;
    final path = Path()
      ..moveTo(mid, h * 0.12)
      ..lineTo(w * 0.88, h * 0.22)
      ..lineTo(w * 0.88, h * 0.88)
      ..lineTo(mid, h * 0.78)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(path, p);
    final pathL = Path()
      ..moveTo(mid, h * 0.12)
      ..lineTo(w * 0.12, h * 0.22)
      ..lineTo(w * 0.12, h * 0.88)
      ..lineTo(mid, h * 0.78)
      ..close();
    canvas.drawPath(pathL, Paint()..color = fill);
    canvas.drawPath(pathL, p);
    canvas.drawLine(Offset(mid, h * 0.12), Offset(mid, h * 0.78), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BookmarkBookGoldIcon extends StatelessWidget {
  const BookmarkBookGoldIcon({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomPaint(
      size: Size(size, size),
      painter: _BookmarkBookPainter(
        stroke: c.accentGold,
        fill: c.backgroundSurface,
      ),
    );
  }
}

class _BookmarkBookPainter extends CustomPainter {
  _BookmarkBookPainter({required this.stroke, required this.fill});

  final Color stroke;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.7, h * 0.7),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(r, Paint()..color = fill);
    canvas.drawRRect(r, p);
    final bm = Path()
      ..moveTo(w * 0.35, h * 0.22)
      ..lineTo(w * 0.5, h * 0.32)
      ..lineTo(w * 0.65, h * 0.22)
      ..lineTo(w * 0.65, h * 0.55)
      ..lineTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.35, h * 0.55)
      ..close();
    canvas.drawPath(bm, Paint()..color = stroke.withValues(alpha: 0.35));
    canvas.drawPath(bm, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
