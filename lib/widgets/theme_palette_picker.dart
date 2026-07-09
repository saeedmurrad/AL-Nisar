import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_color_palettes.dart';
import '../theme/app_theme_colors.dart';

class ThemePalettePicker extends StatelessWidget {
  const ThemePalettePicker({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final c = context.c;

    if (compact) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final palette in AppColorPalette.values)
            _PaletteSwatch(
              palette: palette,
              selected: tp.colorPalette == palette,
              isDark: tp.isDark,
              size: 28,
              onTap: () =>
                  context.read<ThemeProvider>().setColorPalette(palette),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final palette in AppColorPalette.values) ...[
          if (palette != AppColorPalette.values.first)
            const SizedBox(height: 8),
          _PaletteRow(
            palette: palette,
            selected: tp.colorPalette == palette,
            isDark: tp.isDark,
            textColor: c.textPrimary,
            mutedColor: c.textMuted,
            onTap: () => context.read<ThemeProvider>().setColorPalette(palette),
          ),
        ],
      ],
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.palette,
    required this.selected,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  final AppColorPalette palette;
  final bool selected;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            _PaletteSwatch(
              palette: palette,
              selected: selected,
              isDark: isDark,
              size: 32,
              onTap: onTap,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                palette.label,
                style: TextStyle(
                  color: selected ? c.accentGold : textColor,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 20, color: c.accentGold)
            else
              Icon(Icons.circle_outlined, size: 20, color: mutedColor),
          ],
        ),
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.selected,
    required this.isDark,
    required this.size,
    required this.onTap,
  });

  final AppColorPalette palette;
  final bool selected;
  final bool isDark;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final accent = palette
        .colorsFor(isDark ? Brightness.dark : Brightness.light)
        .accentGold;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent,
          border: Border.all(
            color: selected ? c.accentGold : c.borderDefault,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
