import 'dart:math';
import 'package:flutter/material.dart';

class IslamicGeometricPattern extends CustomPainter {
  final Color color;
  final double scale;

  IslamicGeometricPattern({
    required this.color,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    _drawGeometricPattern(canvas, paint, w, h);
  }

  void _drawGeometricPattern(Canvas canvas, Paint paint, double w, double h) {
    const int gridSize = 8;
    final cellW = w / gridSize;
    final cellH = h / gridSize;

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final x = i * cellW + cellW / 2;
        final y = j * cellH + cellH / 2;
        final patternIndex = (i + j) % 4;

        switch (patternIndex) {
          case 0:
            _drawStar(canvas, paint, x, y, cellW / 2.5);
          case 1:
            _drawSquare(canvas, paint, x, y, cellW / 2.5);
          case 2:
            _drawDiamond(canvas, paint, x, y, cellW / 2.5);
          case 3:
            _drawCircleWithDots(canvas, paint, x, y, cellW / 2.5);
        }
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double x, double y, double size) {
    const int points = 6;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final radius = i % 2 == 0 ? size : size * 0.5;
      final px = x + radius * cos(angle);
      final py = y + radius * sin(angle);

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSquare(Canvas canvas, Paint paint, double x, double y, double size) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: size * 2, height: size * 2),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x, y),
        width: size,
        height: size,
      ),
      paint,
    );
  }

  void _drawDiamond(Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    path.moveTo(x, y - size);
    path.lineTo(x + size, y);
    path.lineTo(x, y + size);
    path.lineTo(x - size, y);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCircleWithDots(Canvas canvas, Paint paint, double x, double y, double size) {
    canvas.drawCircle(Offset(x, y), size, paint);
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(x, y), size * 0.3, dotPaint);
  }

  @override
  bool shouldRepaint(IslamicGeometricPattern oldDelegate) => false;
}

class IslamicBorder extends StatelessWidget {
  final Widget child;
  final Color? lineColor;
  final double thickness;

  const IslamicBorder({
    super.key,
    required this.child,
    this.lineColor,
    this.thickness = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = lineColor ?? theme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withValues(alpha: 0.6),
          width: thickness,
        ),
      ),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 8,
            child: CustomPaint(
              painter: IslamicGeometricPattern(
                color: color.withValues(alpha: 0.3),
                scale: 0.5,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 8,
            child: CustomPaint(
              painter: IslamicGeometricPattern(
                color: color.withValues(alpha: 0.3),
                scale: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IslamicDivider extends StatelessWidget {
  final Color? color;
  final double height;
  final double thickness;

  const IslamicDivider({
    super.key,
    this.color,
    this.height = 20,
    this.thickness = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = color ?? theme.primaryColor.withValues(alpha: 0.4);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (height - thickness) / 2),
      child: Column(
        children: [
          Container(
            height: thickness,
            color: dividerColor,
          ),
          SizedBox(height: (height - thickness) / 2),
        ],
      ),
    );
  }
}

class IslamicHeader extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final bool showDecoration;

  const IslamicHeader({
    super.key,
    required this.title,
    this.titleStyle,
    this.showDecoration = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = titleStyle ?? theme.textTheme.headlineSmall;

    return Column(
      children: [
        if (showDecoration) ...[
          SizedBox(
            height: 30,
            child: CustomPaint(
              painter: IslamicGeometricPattern(
                color: theme.primaryColor.withValues(alpha: 0.3),
              ),
              willChange: false,
            ),
          ),
          SizedBox(height: 12),
        ],
        Text(title, style: style),
        if (showDecoration) ...[
          SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: CustomPaint(
              painter: IslamicGeometricPattern(
                color: theme.primaryColor.withValues(alpha: 0.3),
              ),
              willChange: false,
            ),
          ),
        ],
      ],
    );
  }
}