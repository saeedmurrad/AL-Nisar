import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color_palettes.dart';
import 'app_theme_colors.dart';

class AppTheme {
  static ThemeData themeFor({
    required AppColorPalette palette,
    required Brightness brightness,
  }) =>
      _buildTheme(
        brightness: brightness,
        colors: palette.colorsFor(brightness),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppThemeColors colors,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    );

    final poppins = GoogleFonts.poppinsTextTheme();

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      scaffoldBackgroundColor: colors.backgroundPrimary,
      splashColor: colors.accentGold.withValues(alpha: 0.08),
      highlightColor: colors.accentGold.withValues(alpha: 0.05),
      hoverColor: colors.accentGold.withValues(alpha: 0.04),
      dividerColor: colors.borderDefault,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accentGold,
        selectionColor: colors.accentGold.withValues(alpha: 0.20),
        selectionHandleColor: colors.accentGold,
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accentGold,
        onPrimary: colors.backgroundPrimary,
        secondary: colors.accentGold,
        onSecondary: colors.backgroundPrimary,
        error: colors.accentGold,
        onError: colors.backgroundPrimary,
        surface: colors.backgroundSurface,
        onSurface: colors.textPrimary,
      ),
      textTheme: poppins.copyWith(
        titleLarge: poppins.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
        ),
        titleMedium: poppins.titleMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
        ),
        bodyLarge: poppins.bodyLarge?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: poppins.bodyMedium?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        labelLarge: poppins.labelLarge?.copyWith(
          color: colors.textMuted,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.5,
        ),
        labelMedium: poppins.labelMedium?.copyWith(
          color: colors.textMuted,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.5,
        ),
        labelSmall: poppins.labelSmall?.copyWith(
          color: colors.textMuted,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  /// Display headings — Cormorant Garamond (kept name for call-site compatibility).
  static TextStyle cinzelHeading({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = 1.5,
  }) {
    return cormorantGaramond(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle displayTitle({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = 0.5,
  }) =>
      cormorantGaramond(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle sectionCaption({
    Color? color,
    double fontSize = 11,
    double letterSpacing = 1.8,
  }) =>
      lato(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle uiLabel({
    Color? color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
  }) =>
      lato(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: 0.4,
      );

  static TextStyle amiriUrdu({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 2.2,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle cormorantGaramond({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0.6,
    double height = 1.25,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle lato({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.5,
    double letterSpacing = 0.2,
  }) {
    return GoogleFonts.lato(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

