import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme_colors.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final c = context.c;
    final isDark = tp.isDark;

    return InkWell(
      onTap: () => context.read<ThemeProvider>().toggleTheme(),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 56,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: c.backgroundSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.accentGold, width: 1),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _SunIcon(color: c.accentGold),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _MoonIcon(color: c.accentGold),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: c.backgroundElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.borderDefault, width: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SunIcon extends StatelessWidget {
  const _SunIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _SunPainter(color: color)),
    );
  }
}

class _MoonIcon extends StatelessWidget {
  const _MoonIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _MoonPainter(color: color)),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final r = size.shortestSide * 0.28;
    final c1 = Offset(size.width * 0.55, size.height * 0.50);
    final c2 = Offset(size.width * 0.44, size.height * 0.42);

    final outer = Path()..addOval(Rect.fromCircle(center: c1, radius: r));
    final inner = Path()..addOval(Rect.fromCircle(center: c2, radius: r));
    final crescent = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(crescent, p);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SunPainter extends CustomPainter {
  _SunPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 0.45, size.height * 0.5);
    canvas.drawCircle(center, size.shortestSide * 0.16, p);

    final rayLen = size.shortestSide * 0.10;
    final rayFrom = size.shortestSide * 0.26;
    for (int i = 0; i < 8; i++) {
      final a = (i * 3.141592653589793 * 2) / 8;
      final p1 = Offset(
        center.dx + rayFrom * math.cos(a),
        center.dy + rayFrom * math.sin(a),
      );
      final p2 = Offset(
        center.dx + (rayFrom + rayLen) * math.cos(a),
        center.dy + (rayFrom + rayLen) * math.sin(a),
      );
      canvas.drawLine(p1, p2, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SunPainter oldDelegate) =>
      oldDelegate.color != color;
}
