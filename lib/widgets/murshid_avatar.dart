import 'package:flutter/material.dart';

import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';

class MurshidAvatar extends StatelessWidget {
  const MurshidAvatar({
    super.key,
    required this.diameter,
    required this.goldRingWidth,
    this.outerRingWidth = 0,
    this.outerRingColor,
    this.applyGoldenOverlay = false,
  });

  final double diameter;
  final double goldRingWidth;
  final double outerRingWidth;
  final Color? outerRingColor;
  final bool applyGoldenOverlay;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget image = Image.asset(
      'assets/images/sufi_nisar.jpg',
      fit: BoxFit.cover,
    );

    if (applyGoldenOverlay) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.amber.o(0.08),
          BlendMode.srcATop,
        ),
        child: image,
      );
    }

    image = ClipOval(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: image,
      ),
    );

    return Container(
      padding: EdgeInsets.all(outerRingWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: outerRingWidth > 0
            ? (outerRingColor ?? c.borderDefault)
            : Colors.transparent,
      ),
      child: Container(
        padding: EdgeInsets.all(goldRingWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.accentGold,
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.backgroundPrimary,
          ),
          child: image,
        ),
      ),
    );
  }
}

