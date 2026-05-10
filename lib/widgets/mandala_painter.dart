import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/color_utils.dart';

class MandalaPainter extends CustomPainter {
  MandalaPainter({
    this.color = AppColorsDark.accentGold,
    this.opacity = 0.07,
    this.strokeWidth = 1.0,
    this.rings = 5,
    this.petals = 12,
  });

  final Color color;
  final double opacity;
  final double strokeWidth;
  final int rings;
  final int petals;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    final p = Paint()
      ..color = color.o(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (var i = 1; i <= rings; i++) {
      canvas.drawCircle(center, r * (i / (rings + 1)), p);
    }

    final petalRadius = r * 0.55;
    for (var i = 0; i < petals; i++) {
      final a = (math.pi * 2 * i) / petals;
      final o = Offset(
        center.dx + math.cos(a) * (r * 0.25),
        center.dy + math.sin(a) * (r * 0.25),
      );
      canvas.drawCircle(o, petalRadius * 0.32, p);
    }

    for (var i = 0; i < petals; i++) {
      final a = (math.pi * 2 * i) / petals;
      final p1 = Offset(
        center.dx + math.cos(a) * (r * 0.12),
        center.dy + math.sin(a) * (r * 0.12),
      );
      final p2 = Offset(
        center.dx + math.cos(a) * (r * 0.92),
        center.dy + math.sin(a) * (r * 0.92),
      );
      canvas.drawLine(p1, p2, p..strokeWidth = strokeWidth * 0.8);
    }
  }

  @override
  bool shouldRepaint(covariant MandalaPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.rings != rings ||
        oldDelegate.petals != petals;
  }
}

