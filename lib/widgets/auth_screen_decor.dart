import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../theme/app_theme_colors.dart';
import 'mandala_painter.dart';
import 'shimmer_placeholder.dart';

class AuthScreenDecor extends StatelessWidget {
  const AuthScreenDecor({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: c.backgroundPrimary),
        Positioned.fill(
          child: Opacity(
            opacity: 0.08,
            child: CachedNetworkImage(
              imageUrl: DummyData.mosqueDomeGold,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ShimmerPlaceholder(),
              errorWidget: (context, url, error) => const GoldPatternError(),
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.06,
            child: CachedNetworkImage(
              imageUrl: DummyData.candleFlame,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ShimmerPlaceholder(),
              errorWidget: (context, url, error) => const GoldPatternError(),
            ),
          ),
        ),
        Center(
          child: Opacity(
            opacity: 0.07,
            child: CustomPaint(
              painter: MandalaPainter(
                opacity: 0.07,
                strokeWidth: 1.0,
                rings: 6,
                petals: 16,
              ),
              size: const Size(320, 320),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
