import 'package:flutter/material.dart';

import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';

class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, this.color, this.mutedColor});

  final Color? color;
  final Color? mutedColor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = color ?? c.accentGold;
    final muted = mutedColor ?? c.borderDefault;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _line(muted),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '✦',
            style: TextStyle(color: col.o(0.9), fontSize: 14, height: 1),
          ),
        ),
        _line(muted),
      ],
    );
  }

  Widget _line(Color mutedColor) {
    return Container(
      width: 54,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [mutedColor.o(0.0), mutedColor.o(0.9), mutedColor.o(0.0)],
        ),
      ),
    );
  }
}
