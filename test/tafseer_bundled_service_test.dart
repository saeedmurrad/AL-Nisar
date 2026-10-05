import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/services/tafseer_bundled_service.dart';

/// An AssetBundle that has nothing in it, for the missing-content paths.
class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw FlutterError('missing: $key');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = TafseerBundledService();

  test('index lists the bundled surahs in surah order', () async {
    final index = await service.loadIndex();
    expect(index.map((s) => s.id).toList(), [
      'yusuf',
      'raad',
      'ibrahim',
      'hijr',
      'nahl',
      'bani-israel',
      'kahf',
      'maryam',
      'taha',
      'anbiya',
      'hajj',
      'muminun',
      'nur',
      'furqan',
      'shuara',
      'naml',
      'qasas',
      'ankabut',
      'rum',
      'luqman',
      'sajdah',
      'ahzab',
      'saba',
      'fatir',
      'yasin',
      'saffat',
      'sad',
    ]);
    expect(index.map((s) => s.surahNumber).toList(), [
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34,
      35,
      36,
      37,
      38,
    ]);

    final yusuf = index.firstWhere((s) => s.id == 'yusuf');
    expect(yusuf.surahNumber, 12);
    expect(yusuf.rukuCount, 12);
    expect(yusuf.isAvailable, isTrue);
    expect(yusuf.nameUrdu, contains('یوسف'));

    final raad = index.firstWhere((s) => s.id == 'raad');
    expect(raad.surahNumber, 13);
    expect(raad.rukuCount, 6);
    expect(raad.isAvailable, isTrue);
    expect(raad.nameUrdu, contains('رعد'));
  });

  // Table-driven so adding a surah means adding one row, and a malformed
  // source page fails here rather than shipping empty rukus.
  const bundled =
      <
        String,
        ({int number, String name, int rukus, String first, String last})
      >{
        'raad': (
          number: 13,
          name: 'سورۂ رعد',
          rukus: 6,
          first: 'ایک پانی، مختلف پھل',
          last: 'محو و اثبات اور اُمّ الکتاب',
        ),
        'ibrahim': (
          number: 14,
          name: 'سورۂ ابراہیم',
          rukus: 7,
          first: 'ظلمات سے نور تک',
          last: 'تبدیلِ ارض اور بلاغ',
        ),
        'hijr': (
          number: 15,
          name: 'سورۂ الحجر',
          rukus: 6,
          first: 'ذکرِ محفوظ اور مسحور نگاہ',
          last: 'یقین کی آمد تک',
        ),
        'nahl': (
          number: 16,
          name: 'سورۂ النحل',
          rukus: 16,
          first: 'امر کی آمد اور سیدھی راہ',
          last: 'ایک فرد، پوری امت',
        ),
        'bani-israel': (
          number: 17,
          name: 'سورۂ بنی اسرائیل',
          rukus: 12,
          first: 'شبِ اسرا اور مقامِ عبدیت',
          last: 'سبحان سے تکبیر تک',
        ),
        'kahf': (
          number: 18,
          name: 'سورۂ الکہف',
          rukus: 12,
          first: 'عبد کی کتاب اور غارِ دل',
          last: 'کلماتِ رب اور لقاء',
        ),
        'maryam': (
          number: 19,
          name: 'سورۂ مریم',
          rukus: 6,
          first: 'ذکرِ رحمت اور بشارتِ یحییٰ',
          last: 'عبدیتِ کُل، وُدِّ رحمٰن',
        ),
        'taha': (
          number: 20,
          name: 'سورۂ طٰہٰ',
          rukus: 8,
          first: 'وادیِ طویٰ کی آگ',
          last: 'تسبیح، صبر اور رضا',
        ),
        'anbiya': (
          number: 21,
          name: 'سورۂ الانبیاء',
          rukus: 7,
          first: 'تمہارے ذکر والی کتاب',
          last: 'تمام جہانوں کے لیے رحمت',
        ),
        'hajj': (
          number: 22,
          name: 'سورۂ الحج',
          rukus: 10,
          first: 'زلزلۂ ساعت اور خلقِ جدید',
          last: 'مکھی کی مثال اور حقِ جہاد',
        ),
        'muminun': (
          number: 23,
          name: 'سورۂ المؤمنون',
          rukus: 6,
          first: 'فلاح کی منزلیں اور خلقِ آخر',
          last: 'برزخ سے خیر الراحمین تک',
        ),
        'nur': (
          number: 24,
          name: 'سورۂ النور',
          rukus: 9,
          first: 'نور کی چار دیواری',
          last: 'ادبِ رسالت اور علمِ محیط',
        ),
        'furqan': (
          number: 25,
          name: 'سورۂ الفرقان',
          rukus: 6,
          first: 'بندے پر اترا فرقان',
          last: 'رحمٰن کے بندوں کا سراپا',
        ),
        'shuara': (
          number: 26,
          name: 'سورۂ الشعراء',
          rukus: 11,
          first: 'نشانی اور اختیار کی عزت',
          last: 'قلب پر نزول اور اہلِ ذکر',
        ),
        'naml': (
          number: 27,
          name: 'سورۂ النمل',
          rukus: 7,
          first: 'آگ کی صورت میں تجلی',
          last: 'بادل کی طرح گزرتے پہاڑ',
        ),
        'qasas': (
          number: 28,
          name: 'سورۂ القصص',
          rukus: 9,
          first: 'دریا کی گود میں امان',
          last: 'ہر شے فانی، وجہ باقی',
        ),
        'ankabut': (
          number: 29,
          name: 'سورۂ العنکبوت',
          rukus: 7,
          first: 'آزمائش کی بھٹی',
          last: 'ہم میں کوشش، ہماری راہیں',
        ),
        'rum': (
          number: 30,
          name: 'سورۂ الروم',
          rukus: 6,
          first: 'ظاہرِ دنیا اور غفلتِ آخرت',
          last: 'ضعف سے ضعف تک',
        ),
        'luqman': (
          number: 31,
          name: 'سورۂ لقمان',
          rukus: 4,
          first: 'کتابِ حکیم اور اہلِ احسان',
          last: 'غیب کی پانچ کنجیاں',
        ),
        'sajdah': (
          number: 32,
          name: 'سورۂ السجدہ',
          rukus: 3,
          first: 'مٹی، تدبیر اور نفخِ روح',
          last: 'صبر، یقین اور فتح',
        ),
        'ahzab': (
          number: 33,
          name: 'سورۂ الاحزاب',
          rukus: 9,
          first: 'ایک دل، ایک محبوب',
          last: 'امانت کا بارِ عظیم',
        ),
        'saba': (
          number: 34,
          name: 'سورۂ سبا',
          rukus: 6,
          first: 'دونوں جہانوں کی حمد',
          last: 'مثنیٰ و فرادیٰ کی نصیحت',
        ),
        'fatir': (
          number: 35,
          name: 'سورۂ فاطر',
          rukus: 5,
          first: 'رحمت کی فتح',
          last: 'تھاما ہوا وجود',
        ),
        'yasin': (
          number: 36,
          name: 'سورۂ یٰسٓ',
          rukus: 5,
          first: 'قرآنِ حکیم اور امامِ مبین',
          last: 'عدم میں کُن کی سماعت',
        ),
        'saffat': (
          number: 37,
          name: 'سورۂ الصّٰفّٰت',
          rukus: 5,
          first: 'صفیں اور معبودِ واحد',
          last: 'ہر ایک کا مقامِ معلوم',
        ),
        'sad': (
          number: 38,
          name: 'سورۂ صٓ',
          rukus: 5,
          first: 'یاد دہانی والا قرآن',
          last: 'دونوں ہاتھوں کی تخلیق',
        ),
      };

  bundled.forEach((id, want) {
    test(
      '$id parses with ${want.rukus} ordered rukus and full front matter',
      () async {
        final surah = await service.loadSurah(id);
        expect(surah, isNotNull, reason: id);

        expect(
          surah!.rukus.map((r) => r.number).toList(),
          List<int>.generate(want.rukus, (i) => i + 1),
        );
        expect(surah.surahNumber, want.number);
        expect(surah.nameUrdu, want.name);
        expect(surah.titleUrdu, 'تفسیرِ ابنِ عربی');
        expect(surah.basmala, contains('بِسْمِ'));
        expect(surah.prefaceHtml, isNotEmpty);
        expect(surah.key, isNotEmpty);
        expect(surah.colophonHtml, isNotEmpty);

        // The preface carries highlighted terms the reader styles lapis.
        expect(surah.prefaceHtml.join(), contains('class="hl"'));

        expect(surah.rukus.first.titleUrdu, want.first);
        expect(surah.rukus.last.titleUrdu, want.last);

        for (final r in surah.rukus) {
          expect(r.titleUrdu, isNotEmpty, reason: '$id ruku ${r.number} title');
          expect(r.ayahBlock, isNotEmpty, reason: '$id ruku ${r.number} ayah');
          expect(
            r.glossary,
            isNotEmpty,
            reason: '$id ruku ${r.number} glossary',
          );
          expect(
            r.ordinalUrdu,
            contains('رکوع'),
            reason: '$id ruku ${r.number}',
          );
          expect(
            r.ayahRangeUrdu,
            contains('تا'),
            reason: '$id ruku ${r.number}',
          );
        }
      },
    );

    test('$id ruku bodies load and keep their ayah spans', () async {
      for (var n = 1; n <= want.rukus; n++) {
        final html = await service.loadRukuHtml(id, n);
        expect(html, isNotNull, reason: '$id ruku $n');
        expect(html!.trim(), startsWith('<p>'), reason: '$id ruku $n');
        expect(html.contains('class="ayah"'), isTrue, reason: '$id ruku $n');
      }
      expect(await service.loadRukuHtml(id, want.rukus + 1), isNull);
    });
  });

  test(
    'Surah Yusuf parses with 12 ordered rukus and full front matter',
    () async {
      final surah = await service.loadSurah('yusuf');
      expect(surah, isNotNull);

      expect(surah!.rukus.length, 12);
      expect(surah.rukus.first.number, 1);
      expect(surah.rukus.last.number, 12);
      expect(
        surah.rukus.map((r) => r.number).toList(),
        List<int>.generate(12, (i) => i + 1),
      );

      expect(surah.basmala, contains('بِسْمِ'));
      expect(surah.titleUrdu, 'تفسیرِ ابنِ عربی');
      expect(surah.prefaceHtml, hasLength(2));
      expect(surah.key, hasLength(9));
      expect(surah.key.first.meaning, 'عقل');
      expect(surah.colophonHtml, isNotEmpty);
    },
  );

  test('every ruku has a title, ayah block and glossary', () async {
    final surah = await service.loadSurah('yusuf');
    for (final r in surah!.rukus) {
      expect(r.titleUrdu, isNotEmpty, reason: 'ruku ${r.number} title');
      expect(r.ayahBlock, isNotEmpty, reason: 'ruku ${r.number} ayah block');
      expect(r.ordinalUrdu, contains('رکوع'), reason: 'ruku ${r.number}');
      expect(r.ayahRangeUrdu, contains('تا'), reason: 'ruku ${r.number}');
      expect(r.glossary, isNotEmpty, reason: 'ruku ${r.number} glossary');
    }

    expect(surah.rukus.first.titleUrdu, 'خوابِ ازل');
    expect(surah.rukus.first.eyebrow, 'پہلا رکوع · آیات ۱ تا ۶');
  });

  test(
    'ruku body HTML loads for every ruku and keeps the ayah spans',
    () async {
      for (var n = 1; n <= 12; n++) {
        final html = await service.loadRukuHtml('yusuf', n);
        expect(html, isNotNull, reason: 'ruku $n');
        expect(html!.trim(), startsWith('<p>'), reason: 'ruku $n');
      }

      final first = await service.loadRukuHtml('yusuf', 1);
      expect(first!.contains('class="ayah"'), isTrue);
    },
  );

  test('fields rendered as plain Text carry no markup', () async {
    // Bani Israel wraps some ayah blocks in <span class="ayah" data-a="N">.
    // Those fields are rendered with Text, so tags would show literally.
    for (final summary in await service.loadIndex()) {
      final surah = (await service.loadSurah(summary.id))!;
      final plain = <String, String>{
        'basmala': surah.basmala,
        'titleUrdu': surah.titleUrdu,
        'subtitleUrdu': surah.subtitleUrdu,
        'kicker': surah.kicker,
        'nameUrdu': surah.nameUrdu,
        for (final k in surah.key) 'key.${k.term}': '${k.term} ${k.meaning}',
        for (final r in surah.rukus) ...{
          'ruku${r.number}.title': r.titleUrdu,
          'ruku${r.number}.ayahBlock': r.ayahBlock,
          'ruku${r.number}.eyebrow': r.eyebrow,
          for (final g in r.glossary) 'ruku${r.number}.term': g.term,
        },
      };
      plain.forEach((field, value) {
        expect(value, isNot(contains('<')), reason: '${summary.id} $field');
        expect(value, isNot(contains('>')), reason: '${summary.id} $field');
      });
    }
  });

  test('preface, colophon and glossary definitions keep their HTML', () async {
    final yusuf = (await service.loadSurah('yusuf'))!;
    expect(yusuf.prefaceHtml.join(), contains('<p>'));
    final bolded = yusuf.rukus
        .expand((r) => r.glossary)
        .where((g) => g.definitionHtml.contains('<b>'));
    expect(bolded, isNotEmpty);
  });

  test('ruku asset paths are zero-padded', () {
    expect(
      TafseerBundledService.rukuPath('yusuf', 3),
      'assets/tafseer/yusuf/rukus/03.html',
    );
    expect(
      TafseerBundledService.rukuPath('yusuf', 12),
      'assets/tafseer/yusuf/rukus/12.html',
    );
  });

  test('missing content degrades to empty/null rather than throwing', () async {
    expect(await service.loadSurah(''), isNull);
    expect(await service.loadSurah('baqarah'), isNull);
    expect(await service.loadRukuHtml('raad', 0), isNull);
    expect(await service.loadRukuHtml('yusuf', 0), isNull);
    expect(await service.loadRukuHtml('yusuf', 99), isNull);

    final empty = TafseerBundledService(bundle: _EmptyBundle());
    expect(await empty.loadIndex(), isEmpty);
    expect(await empty.loadSurah('yusuf'), isNull);
    expect(await empty.loadRukuHtml('yusuf', 1), isNull);
  });
}
