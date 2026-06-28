import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';

class FontScaleControl extends StatelessWidget {
  const FontScaleControl({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final c = context.c;
    final buttonSize = compact ? 36.0 : 40.0;
    final iconSize = compact ? 18.0 : 20.0;
    final labelSize = compact ? 12.0 : 13.0;

    return Row(
      children: [
        _ScaleButton(
          label: 'A−',
          enabled: tp.canDecreaseFont,
          size: buttonSize,
          fontSize: iconSize,
          onTap: () => context.read<ThemeProvider>().decreaseFontSize(),
        ),
        Expanded(
          child: Text(
            tp.fontScaleLabel,
            textAlign: TextAlign.center,
            style: AppTheme.lato(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ),
        _ScaleButton(
          label: 'A+',
          enabled: tp.canIncreaseFont,
          size: buttonSize,
          fontSize: iconSize,
          onTap: () => context.read<ThemeProvider>().increaseFontSize(),
        ),
      ],
    );
  }
}

class _ScaleButton extends StatelessWidget {
  const _ScaleButton({
    required this.label,
    required this.enabled,
    required this.size,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final double size;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? c.backgroundSurface : c.backgroundElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? c.accentGold : c.borderDefault,
            width: enabled ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.lato(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: enabled ? c.accentGold : c.textFaint,
          ),
        ),
      ),
    );
  }
}
