import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';

class ShimmerPlaceholder extends StatefulWidget {
  const ShimmerPlaceholder({super.key, this.borderRadius});

  final BorderRadius? borderRadius;

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(0),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final dx = (t * 2 - 0.5);
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: c.backgroundSurface),
              Transform.translate(
                offset: Offset(dx * 220, 0),
                child: Transform.rotate(
                  angle: -math.pi / 8,
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          c.borderDefault.o(0.38),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class GoldPatternError extends StatelessWidget {
  const GoldPatternError({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomPaint(
      painter: _GoldPatternPainter(
        background: c.backgroundSurface,
        stroke: c.accentGold.o(0.35),
      ),
      child: Container(color: c.backgroundSurface),
    );
  }
}

class _GoldPatternPainter extends CustomPainter {
  _GoldPatternPainter({required this.background, required this.stroke});

  final Color background;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = background
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bg);

    final p = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final step = math.max(18.0, math.min(size.width, size.height) / 6);
    for (double y = -step; y <= size.height + step; y += step) {
      for (double x = -step; x <= size.width + step; x += step) {
        final c = Offset(x, y);
        final r = step * 0.42;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = (math.pi * 2 * i) / 6;
          final pt = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
          if (i == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        path.close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
