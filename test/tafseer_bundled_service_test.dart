import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/services/tafseer_bundled_service.dart';

/// An AssetBundle that has nothing in it, for the missing-content paths.
class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw FlutterError('missing: $key');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = TafseerBundledService();

  test('index lists Surah Yusuf', () async {
    final index = await service.loadIndex();
    expect(index, isNotEmpty);

    final yusuf = index.firstWhere((s) => s.id == 'yusuf');
    expect(yusuf.surahNumber, 12);
    expect(yusuf.rukuCount, 12);
    expect(yusuf.isAvailable, isTrue);
    expect(yusuf.nameUrdu, contains('یوسف'));
  });

  test('Surah Yusuf parses with 12 ordered rukus and full front matter', () async {
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
  });

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

  test('ruku body HTML loads for every ruku and keeps the ayah spans', () async {
    for (var n = 1; n <= 12; n++) {
      final html = await service.loadRukuHtml('yusuf', n);
      expect(html, isNotNull, reason: 'ruku $n');
      expect(html!.trim(), startsWith('<p>'), reason: 'ruku $n');
    }

    final first = await service.loadRukuHtml('yusuf', 1);
    expect(first!.contains('class="ayah"'), isTrue);
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
    expect(await service.loadRukuHtml('yusuf', 0), isNull);
    expect(await service.loadRukuHtml('yusuf', 99), isNull);

    final empty = TafseerBundledService(bundle: _EmptyBundle());
    expect(await empty.loadIndex(), isEmpty);
    expect(await empty.loadSurah('yusuf'), isNull);
    expect(await empty.loadRukuHtml('yusuf', 1), isNull);
  });
}
