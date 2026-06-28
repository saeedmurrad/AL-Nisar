import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiritual_learning_app/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider font scale', () {
    test('default step is 2 with scale 1.0', () {
      final provider = ThemeProvider();
      expect(provider.fontScaleStep, ThemeProvider.defaultFontScaleStep);
      expect(provider.fontScale, 1.0);
      expect(provider.fontScaleLabel, 'Default');
    });

    test('increaseFontSize steps up until max', () {
      final provider = ThemeProvider();
      expect(provider.canIncreaseFont, isTrue);

      provider.increaseFontSize();
      expect(provider.fontScaleStep, 3);
      expect(provider.fontScale, 1.06);
      expect(provider.fontScaleLabel, 'Large');

      provider.increaseFontSize();
      expect(provider.fontScaleStep, 4);
      expect(provider.fontScale, 1.12);
      expect(provider.canIncreaseFont, isFalse);

      provider.increaseFontSize();
      expect(provider.fontScaleStep, 4);
    });

    test('decreaseFontSize steps down until min', () {
      final provider = ThemeProvider();
      expect(provider.canDecreaseFont, isTrue);

      provider.decreaseFontSize();
      expect(provider.fontScaleStep, 1);
      expect(provider.fontScale, 0.94);

      provider.decreaseFontSize();
      expect(provider.fontScaleStep, 0);
      expect(provider.fontScale, 0.88);
      expect(provider.canDecreaseFont, isFalse);

      provider.decreaseFontSize();
      expect(provider.fontScaleStep, 0);
    });

    test('clampFontScaleStep bounds invalid values', () {
      expect(ThemeProvider.clampFontScaleStep(-1), 0);
      expect(ThemeProvider.clampFontScaleStep(2), 2);
      expect(ThemeProvider.clampFontScaleStep(99), ThemeProvider.fontScaleSteps.length - 1);
    });
  });
}
