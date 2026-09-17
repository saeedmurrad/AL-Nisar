import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spiritual_learning_app/screens/tafseer_list_screen.dart';
import 'package:spiritual_learning_app/screens/tafseer_ruku_screen.dart';
import 'package:spiritual_learning_app/screens/tafseer_surah_screen.dart';
import 'package:spiritual_learning_app/services/tafseer_bundled_service.dart';
import 'package:spiritual_learning_app/theme/app_theme_colors.dart';
import 'package:spiritual_learning_app/theme/tafseer_theme.dart';

/// The app's real palette isn't needed here — any AppThemeColors will do, since
/// the tafseer screens override it with their own reading palette.
const _colors = AppThemeColors(
  backgroundPrimary: Color(0xFFF5F8F5),
  backgroundSurface: Color(0xFFFFFFFF),
  backgroundElevated: Color(0xFFEFF3EF),
  backgroundInput: Color(0xFFFFFFFF),
  accentGold: Color(0xFF0E7A55),
  textPrimary: Color(0xFF11221A),
  textSecondary: Color(0xFF3A4A42),
  textMuted: Color(0xFF6B7A72),
  textFaint: Color(0xFF9AA79F),
  borderDefault: Color(0xFFD7E0DA),
  borderFaint: Color(0xFFE8EEEA),
);

/// Serves the repo's real asset files synchronously, so the screens' loads
/// resolve on microtasks and plain `pump()` is enough to see the result.
class _DiskBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) =>
      SynchronousFuture(ByteData.view(File(key).readAsBytesSync().buffer));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(File(key).readAsStringSync());

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) => parser(File(key).readAsStringSync());
}

final _service = TafseerBundledService(bundle: _DiskBundle());

Widget _app(Widget home, {Brightness brightness = Brightness.light}) {
  final router = GoRouter(
    initialLocation: '/x',
    routes: [GoRoute(path: '/x', builder: (_, _) => home)],
  );
  final base = brightness == Brightness.dark
      ? ThemeData.dark()
      : ThemeData.light();
  return MaterialApp.router(
    routerConfig: router,
    theme: base.copyWith(extensions: const [_colors]),
  );
}

/// Pumps a fixed number of frames rather than settling: google_fonts schedules
/// work that never quiets in tests.
Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(_app(home, brightness: brightness));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('index screen lists every bundled surah', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, TafseerListScreen(service: _service));

    expect(find.text('Ishari Commentary'), findsOneWidget);

    // One card per surah, each with its own Urdu name and number badge.
    for (final (name, badge) in const [
      ('سورۂ یوسف', '۱۲'),
      ('سورۂ رعد', '۱۳'),
      ('سورۂ ابراہیم', '۱۴'),
      ('سورۂ الحجر', '۱۵'),
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
      expect(find.text(badge), findsOneWidget, reason: badge);
    }

    expect(find.text('12 rukus · Urdu'), findsOneWidget);
    expect(find.text('7 rukus · Urdu'), findsOneWidget);
    // Ar-Ra'd and Al-Hijr both have six.
    expect(find.text('6 rukus · Urdu'), findsNWidgets(2));
  });

  testWidgets('each surah screen renders its own contents', (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final (id, first, last, lastNum, pastEnd) in const [
      ('raad', 'ایک پانی، مختلف پھل', 'محو و اثبات اور اُمّ الکتاب', '۶', '۷'),
      ('ibrahim', 'ظلمات سے نور تک', 'تبدیلِ ارض اور بلاغ', '۷', '۸'),
      ('hijr', 'ذکرِ محفوظ اور مسحور نگاہ', 'یقین کی آمد تک', '۶', '۷'),
    ]) {
      await _pump(tester, TafseerSurahScreen(surahId: id, service: _service));

      expect(find.text('فہرستِ رکوع'), findsOneWidget, reason: id);
      expect(find.text(first), findsOneWidget, reason: '$id first');
      expect(find.text(last), findsOneWidget, reason: '$id last');
      // The contents stop at this surah's own ruku count.
      expect(find.text(lastNum), findsOneWidget, reason: '$id last number');
      expect(find.text(pastEnd), findsNothing, reason: '$id past end');
    }
  });

  testWidgets('Al-Hijr reader renders the Iblis ruku with its glossary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'hijr', rukuNumber: 3, service: _service),
    );

    expect(find.text('تیسرا رکوع · آیات ۲۶ تا ۴۴'), findsOneWidget);
    expect(find.text('نفخِ روح اور سجدۂ ملائک'), findsOneWidget);
    expect(find.text('مشکل الفاظ اور اصطلاحاتِ فقر'), findsOneWidget);
    expect(find.text('صلصال'), findsOneWidget); // a glossary term

    // Mid-surah: both directions available.
    for (final label in const ['← پچھلا رکوع', 'اگلا رکوع →']) {
      final b = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(b.onPressed, isNotNull, reason: label);
    }
  });

  testWidgets('Ar-Rad reader renders body and glossary, and ends at ruku 6', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'raad', rukuNumber: 6, service: _service),
    );

    expect(find.text('چھٹا رکوع · آیات ۳۸ تا ۴۳'), findsOneWidget);
    expect(find.text('محو و اثبات اور اُمّ الکتاب'), findsOneWidget);
    expect(find.text('مشکل الفاظ اور اصطلاحاتِ فقر'), findsOneWidget);

    final next = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('اگلا رکوع →'),
        matching: find.byType(OutlinedButton),
      ),
    );
    final prev = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('← پچھلا رکوع'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(next.onPressed, isNull); // last ruku of this surah
    expect(prev.onPressed, isNotNull);
  });

  testWidgets('reader adopts the dark paper palette in dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 1, service: _service),
      brightness: Brightness.dark,
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, kTafseerDarkColors.backgroundPrimary);

    final spans = <TextSpan>[];
    for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
      rt.text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').isNotEmpty) spans.add(span);
        return true;
      });
    }
    final ayah = spans.firstWhere((s) => (s.text ?? '').contains('نَحْنُ نَقُصُّ'));
    expect(ayah.style?.color, kTafseerDarkColors.accentGold);
  });

  testWidgets('surah screen renders masthead, key and all 12 ruku rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, TafseerSurahScreen(surahId: 'yusuf', service: _service));

    expect(find.text('تفسیرِ ابنِ عربی'), findsOneWidget);
    expect(find.textContaining('بِسْمِ'), findsWidgets);
    expect(find.text('اردو · اشاری تفسیر · رکوع بہ رکوع'), findsOneWidget);
    expect(find.text('فہرستِ رکوع'), findsOneWidget);

    // Every ruku title is listed in the contents.
    for (final title in const [
      'خوابِ ازل',
      'کنویں کی خلوت',
      'برہانِ رب',
      'آیت، بصیرت اور عبور',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    // Urdu-Indic numerals in the index, not Western digits.
    expect(find.text('۱'), findsOneWidget);
    expect(find.text('۱۲'), findsOneWidget);
  });

  testWidgets('surah screen shows a branded state for an unknown surah', (
    tester,
  ) async {
    await _pump(tester, TafseerSurahScreen(surahId: 'baqarah', service: _service));
    expect(find.text('Tafseer not found'), findsOneWidget);
  });

  testWidgets('ruku screen renders marker, ayah block, body and glossary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 1, service: _service),
    );

    expect(find.text('پہلا رکوع · آیات ۱ تا ۶'), findsOneWidget);
    expect(find.text('ع'), findsOneWidget);
    expect(find.text('خوابِ ازل'), findsOneWidget);
    expect(
      find.text('الٓرٰ ۚ تِلْكَ اٰيٰتُ الْكِتٰبِ الْمُبِيْنِ'),
      findsOneWidget,
    );

    // Body prose came through the HTML renderer.
    expect(find.textContaining('حروفِ مقطعات'), findsWidgets);

    // Glossary panel.
    expect(find.text('مشکل الفاظ اور اصطلاحاتِ فقر'), findsOneWidget);
    expect(find.text('نفَسِ رحمانی'), findsOneWidget);

    // Paging controls: no previous ruku before #1, next is available.
    final prev = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('← پچھلا رکوع'),
        matching: find.byType(OutlinedButton),
      ),
    );
    final next = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('اگلا رکوع →'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(prev.onPressed, isNull);
    expect(next.onPressed, isNotNull);
  });

  testWidgets('last ruku disables Next', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 12, service: _service),
    );

    final next = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('اگلا رکوع →'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('inline .ayah spans are restyled saffron, body prose is not', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 1, service: _service),
    );

    // Collect every styled leaf span rendered by flutter_html.
    final spans = <TextSpan>[];
    for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
      rt.text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').isNotEmpty) spans.add(span);
        return true;
      });
    }

    TextSpan spanContaining(String needle) => spans.firstWhere(
      (s) => (s.text ?? '').contains(needle),
      orElse: () => throw StateError('no span containing "\$needle"'),
    );

    // An inline Quranic fragment carried by <span class="ayah">.
    final ayah = spanContaining('نَحْنُ نَقُصُّ');
    expect(ayah.style?.color, kTafseerLightColors.accentGold);
    expect(ayah.style?.fontWeight, FontWeight.w700);

    // Surrounding Urdu prose keeps the ink colour, not the ayah colour.
    final prose = spanContaining('سورت کا آغاز');
    expect(prose.style?.color, kTafseerLightColors.textPrimary);
    expect(prose.style?.color, isNot(kTafseerLightColors.accentGold));

    // The two are rendered in different families.
    expect(ayah.style?.fontFamily, isNot(prose.style?.fontFamily));
  });

  testWidgets('out-of-range ruku shows a branded state', (tester) async {
    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 99, service: _service),
    );
    expect(find.text('Ruku not found'), findsOneWidget);
  });
}
