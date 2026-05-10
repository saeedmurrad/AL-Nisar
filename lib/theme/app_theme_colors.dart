import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.backgroundPrimary,
    required this.backgroundSurface,
    required this.backgroundElevated,
    required this.backgroundInput,
    required this.accentGold,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.borderDefault,
    required this.borderFaint,
  });

  final Color backgroundPrimary;
  final Color backgroundSurface;
  final Color backgroundElevated;
  final Color backgroundInput;
  final Color accentGold;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color borderDefault;
  final Color borderFaint;

  @override
  AppThemeColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundSurface,
    Color? backgroundElevated,
    Color? backgroundInput,
    Color? accentGold,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textFaint,
    Color? borderDefault,
    Color? borderFaint,
  }) {
    return AppThemeColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSurface: backgroundSurface ?? this.backgroundSurface,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      backgroundInput: backgroundInput ?? this.backgroundInput,
      accentGold: accentGold ?? this.accentGold,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      borderDefault: borderDefault ?? this.borderDefault,
      borderFaint: borderFaint ?? this.borderFaint,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      backgroundPrimary: Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSurface: Color.lerp(backgroundSurface, other.backgroundSurface, t)!,
      backgroundElevated:
          Color.lerp(backgroundElevated, other.backgroundElevated, t)!,
      backgroundInput: Color.lerp(backgroundInput, other.backgroundInput, t)!,
      accentGold: Color.lerp(accentGold, other.accentGold, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderFaint: Color.lerp(borderFaint, other.borderFaint, t)!,
    );
  }
}

extension ThemeColorsX on BuildContext {
  AppThemeColors get c => Theme.of(this).extension<AppThemeColors>()!;
}

