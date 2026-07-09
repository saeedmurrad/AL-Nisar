import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_color_palettes.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const _modeKey = 'theme_mode';
  static const _paletteKey = 'color_palette';
  static const _fontScaleStepKey = 'font_scale_step';

  static const List<double> fontScaleSteps = [0.88, 0.94, 1.0, 1.06, 1.12];

  static const List<String> fontScaleLabels = [
    'Small',
    'Medium',
    'Default',
    'Large',
    'Extra Large',
  ];

  static const int defaultFontScaleStep = 2;

  ThemeMode _themeMode = ThemeMode.light;
  AppColorPalette _colorPalette = AppColorPalette.defaultPalette;
  int _fontScaleStep = defaultFontScaleStep;

  ThemeMode get themeMode => _themeMode;
  AppColorPalette get colorPalette => _colorPalette;
  bool get isDark => _themeMode == ThemeMode.dark;

  int get fontScaleStep => _fontScaleStep;

  double get fontScale => fontScaleSteps[_fontScaleStep];

  String get fontScaleLabel => fontScaleLabels[_fontScaleStep];

  bool get canDecreaseFont => _fontScaleStep > 0;

  bool get canIncreaseFont => _fontScaleStep < fontScaleSteps.length - 1;

  ThemeData get lightTheme =>
      AppTheme.themeFor(palette: _colorPalette, brightness: Brightness.light);

  ThemeData get darkTheme =>
      AppTheme.themeFor(palette: _colorPalette, brightness: Brightness.dark);

  static int clampFontScaleStep(int step) {
    if (step < 0) return 0;
    if (step >= fontScaleSteps.length) return fontScaleSteps.length - 1;
    return step;
  }

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _save();
  }

  void setColorPalette(AppColorPalette palette) {
    if (_colorPalette == palette) return;
    _colorPalette = palette;
    notifyListeners();
    _save();
  }

  void decreaseFontSize() {
    if (!canDecreaseFont) return;
    _fontScaleStep--;
    notifyListeners();
    _save();
  }

  void increaseFontSize() {
    if (!canIncreaseFont) return;
    _fontScaleStep++;
    notifyListeners();
    _save();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_modeKey);
    if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _colorPalette = AppColorPalette.fromName(prefs.getString(_paletteKey));
    _fontScaleStep = clampFontScaleStep(
      prefs.getInt(_fontScaleStepKey) ?? defaultFontScaleStep,
    );
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, isDark ? 'dark' : 'light');
    await prefs.setString(_paletteKey, _colorPalette.name);
    await prefs.setInt(_fontScaleStepKey, _fontScaleStep);
  }
}
