import 'package:flutter/material.dart';

import 'app_theme_colors.dart';

/// Reading palette for the Tafseer section, ported from the published
/// "تفسیرِ ابنِ عربی" page: aged paper, lapis headings, saffron ayah text.
///
/// Applied the same way as `emeraldChromeTheme` in `widgets/islamic_ui.dart` —
/// wrap the section's subtree in [tafseerTheme] so every descendant's
/// `context.c` resolves to these colours. Never capture an outer `c`: colours
/// must be read from a context *below* the wrapper.
const kTafseerLightColors = AppThemeColors(
  backgroundPrimary: Color(0xFFEFE8D6), // --paper
  backgroundSurface: Color(0xFFE6DDC6), // --paper-2
  backgroundElevated: Color(0xFFE7DFC9), // --glossary
  backgroundInput: Color(0xFFE6DDC6),
  accentGold: Color(0xFFB07A12), // --saffron
  textPrimary: Color(0xFF1F2233), // --ink
  textSecondary: Color(0xFF4A4D5C), // --ink-soft
  textMuted: Color(0xFF7A776C), // --muted
  textFaint: Color(0xFFA39E8E),
  borderDefault: Color(0xFFC9BE9F), // --rule
  borderFaint: Color(0xFFD9D0B5),
);

const kTafseerDarkColors = AppThemeColors(
  backgroundPrimary: Color(0xFF12141E),
  backgroundSurface: Color(0xFF181B28),
  backgroundElevated: Color(0xFF1B1F2E),
  backgroundInput: Color(0xFF181B28),
  accentGold: Color(0xFFE0B04A),
  textPrimary: Color(0xFFE9E2D0),
  textSecondary: Color(0xFFC7C0AE),
  textMuted: Color(0xFF8E8A7C),
  textFaint: Color(0xFF6B6859),
  borderDefault: Color(0xFF33384C),
  borderFaint: Color(0xFF262B3B),
);

/// Lapis accents. These have no equivalent in [AppThemeColors], so they are
/// resolved off the ambient brightness instead of the theme extension.
abstract final class TafseerPalette {
  static const _lapisLight = Color(0xFF1E3A8A);
  static const _lapisDark = Color(0xFF9FB4F2);
  static const _lapisSoftLight = Color(0xFF3B5BB5);
  static const _lapisSoftDark = Color(0xFF7F98E6);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Ruku titles and the page's main heading.
  static Color lapis(BuildContext context) =>
      isDark(context) ? _lapisDark : _lapisLight;

  /// Inline highlighted phrases (`.hl`).
  static Color lapisSoft(BuildContext context) =>
      isDark(context) ? _lapisSoftDark : _lapisSoftLight;
}

/// Wraps [context]'s theme with the tafseer reading palette.
ThemeData tafseerTheme(BuildContext context) {
  final base = Theme.of(context);
  final colors = base.brightness == Brightness.dark
      ? kTafseerDarkColors
      : kTafseerLightColors;
  return base.copyWith(
    scaffoldBackgroundColor: colors.backgroundPrimary,
    extensions: [colors],
  );
}
