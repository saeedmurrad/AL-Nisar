import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';

class GoldCard extends StatelessWidget {
  const GoldCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? c.backgroundSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: c.borderDefault,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

