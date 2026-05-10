import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_theme_colors.dart';

class AppTheme {
  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        colors: const AppThemeColors(
          backgroundPrimary: AppColorsDark.backgroundPrimary,
          backgroundSurface: AppColorsDark.backgroundSurface,
          backgroundElevated: AppColorsDark.backgroundElevated,
          backgroundInput: AppColorsDark.backgroundInput,
          accentGold: AppColorsDark.accentGold,
          textPrimary: AppColorsDark.textPrimary,
          textSecondary: AppColorsDark.textSecondary,
          textMuted: AppColorsDark.textMuted,
          textFaint: AppColorsDark.textFaint,
          borderDefault: AppColorsDark.borderDefault,
          borderFaint: AppColorsDark.borderFaint,
        ),
      );

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        colors: const AppThemeColors(
          backgroundPrimary: AppColorsLight.backgroundPrimary,
          backgroundSurface: AppColorsLight.backgroundSurface,
          backgroundElevated: AppColorsLight.backgroundElevated,
          backgroundInput: AppColorsLight.backgroundInput,
          accentGold: AppColorsLight.accentGold,
          textPrimary: AppColorsLight.textPrimary,
          textSecondary: AppColorsLight.textSecondary,
          textMuted: AppColorsLight.textMuted,
          textFaint: AppColorsLight.textFaint,
          borderDefault: AppColorsLight.borderDefault,
          borderFaint: AppColorsLight.borderFaint,
        ),
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
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
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

  // Kept method name to avoid touching screen structure.
  static TextStyle cinzelHeading({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = 1.5,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

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

