import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/theme/app_theme_colors.dart';
import 'package:spiritual_learning_app/widgets/tafseer_copy_button.dart';

const _colors = AppThemeColors(
  backgroundPrimary: Color(0xFFF5F8F5),
  backgroundSurface: Color(0xFFFFFFFF),
  backgroundElevated: Color(0xFFEFF3EF),
  backgroundInput: Color(0xFFFFFFFF),
  accentGold: Color(0xFFD4AF37),
  textPrimary: Color(0xFF11221A),
  textSecondary: Color(0xFF3A4A42),
  textMuted: Color(0xFF6B7A72),
  textFaint: Color(0xFF9AA79F),
  borderDefault: Color(0xFFD7E0DA),
  borderFaint: Color(0xFFE8EEEA),
);

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData.light().copyWith(extensions: const [_colors]),
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('hidden for a regular member', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      TafseerCopyButton(isSuperAdmin: false, onCopy: () => taps++),
    );

    expect(find.byType(IconButton), findsNothing);
    expect(find.byIcon(Icons.copy_all_outlined), findsNothing);
    expect(taps, 0);
  });

  testWidgets('shown to a super admin and fires the callback', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      TafseerCopyButton(isSuperAdmin: true, onCopy: () => taps++),
    );

    expect(find.byIcon(Icons.copy_all_outlined), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('takes its colour from the ambient theme, not a literal', (
    tester,
  ) async {
    await _pump(tester, TafseerCopyButton(isSuperAdmin: true, onCopy: () {}));
    final icon = tester.widget<Icon>(find.byIcon(Icons.copy_all_outlined));
    expect(icon.color, _colors.accentGold);
  });
}
