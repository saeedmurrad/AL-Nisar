import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/models/tafseer_models.dart';
import 'package:spiritual_learning_app/services/tafseer_bundled_service.dart';
import 'package:spiritual_learning_app/utils/tafseer_plain_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stripHtml', () {
    test('removes tags but keeps the text', () {
      expect(stripHtml('<p>ایک <span class="ayah">کلمہ</span> ہے</p>'),
          'ایک کلمہ ہے');
    });

    test('removes tags carrying attributes', () {
      // Surah Bani Israel tags its ayah spans with data-a="12"; a naive
      // "<span>" match would leave the opening tag behind.
      expect(
        stripHtml('<span class="ayah" data-a="12">اَسْرٰى</span> بِعَبْدِهٖ'),
        'اَسْرٰى بِعَبْدِهٖ',
      );
      expect(stripHtml('<span class="ayah" data-a="1">x</span>'), isNot(contains('<')));
    });

    test('collapses newlines and runs of spaces', () {
      expect(stripHtml('ایک\n   دو'), 'ایک دو');
    });
  });

  group('tafseerRukuPlainText', () {
    late TafseerSurah surah;
    late String body;

    setUpAll(() async {
      final service = TafseerBundledService();
      surah = (await service.loadSurah('bani-israel'))!;
      body = (await service.loadRukuHtml('bani-israel', 1))!;
    });

    test('opens with surah, eyebrow, title and ayah block', () {
      final text = tafseerRukuPlainText(
        surah: surah,
        ruku: surah.rukus.first,
        bodyHtml: body,
      );
      final lines = text.split('\n');
      expect(lines[0], 'سورۂ بنی اسرائیل');
      expect(lines[1], 'پہلا رکوع · آیات ۱ تا ۱۰');
      expect(lines[2], 'شبِ اسرا اور مقامِ عبدیت');
      expect(text, contains('سُبْحٰنَ الَّذِيْۤ اَسْرٰى'));
    });

    test('carries the prose and the full glossary, with no markup', () {
      final ruku = surah.rukus.first;
      final text = tafseerRukuPlainText(
        surah: surah,
        ruku: ruku,
        bodyHtml: body,
      );

      expect(text, contains('مشکل الفاظ اور اصطلاحاتِ فقر'));
      for (final g in ruku.glossary) {
        expect(text, contains(g.term), reason: g.term);
      }

      // Nothing tag-shaped survives, including the data-a attributes.
      expect(text, isNot(contains('<')));
      expect(text, isNot(contains('data-a')));
      expect(text, isNot(contains('class="ayah"')));
    });

    test('every bundled ruku produces non-trivial text', () async {
      final service = TafseerBundledService();
      for (final s in await service.loadIndex()) {
        final full = (await service.loadSurah(s.id))!;
        for (final r in full.rukus) {
          final html = (await service.loadRukuHtml(s.id, r.number))!;
          final text = tafseerRukuPlainText(
            surah: full,
            ruku: r,
            bodyHtml: html,
          );
          expect(text.length, greaterThan(500), reason: '${s.id} ruku ${r.number}');
          expect(text, isNot(contains('<')), reason: '${s.id} ruku ${r.number}');
        }
      }
    });
  });
}
