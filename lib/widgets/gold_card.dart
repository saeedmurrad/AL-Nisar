import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import 'mandala_painter.dart';

class GoldCard extends StatelessWidget {
  const GoldCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor,
    this.showWatermark = false,
    this.showHighlight = true,
    this.clipChild = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool showWatermark;
  final bool showHighlight;
  final bool clipChild;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final surface = backgroundColor ?? c.backgroundSurface;

    Widget content = Padding(padding: padding, child: child);

    if (showWatermark) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -18,
            right: -10,
            child: CustomPaint(
              painter: MandalaPainter(
                color: c.accentGold,
                opacity: 0.06,
                strokeWidth: 0.9,
                rings: 4,
                petals: 12,
              ),
              size: const Size(120, 120),
            ),
          ),
          content,
        ],
      );
    }

    return Container(
      clipBehavior: clipChild ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        borderRadius: AppLayout.cardRadius,
        border: Border.all(color: c.accentGold.o(0.22), width: 0.6),
        gradient: showHighlight
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(c.accentGold.o(0.06), surface),
                  surface,
                ],
              )
            : null,
        color: showHighlight ? null : surface,
        boxShadow: [
          BoxShadow(
            color: c.accentGold.o(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: content,
    );
  }
}
