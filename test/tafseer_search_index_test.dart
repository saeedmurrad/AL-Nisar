import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/models/tafseer_search.dart';
import 'package:spiritual_learning_app/services/tafseer_bundled_service.dart';
import 'package:spiritual_learning_app/services/tafseer_search_service.dart';
import 'package:spiritual_learning_app/utils/arabic_search_text.dart';
import 'package:spiritual_learning_app/utils/tafseer_search_index.dart';

import '../tool/build_tafseer_search_index.dart';

/// The real bundle with the precomputed index hidden, so the fallback path can
/// be exercised against the same content.
class _WithoutSearchIndex extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (key == 'assets/tafseer/search-index.json') {
      throw FlutterError('search-index.json is not bundled');
    }
    return rootBundle.loadString(key, cache: cache);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the committed index matches the content it was built from', () async {
    final fresh = await buildTafseerSearchIndexJson();
    final committed = await File(tafseerSearchIndexPath()).readAsString();
    if (committed != fresh) {
      fail(
        'assets/tafseer/search-index.json is stale '
        '(${committed.length} chars on disk, ${fresh.length} rebuilt). '
        'Run: dart run tool/build_tafseer_search_index.dart',
      );
    }
  });

  test('search reads the precomputed index, not the content', () async {
    final search = TafseerSearchService();
    await search.buildIndex();
    expect(search.usedPrecomputedIndex, isTrue);
  });

  test('every passage folds to what matching runs against', () async {
    final passages = decodeTafseerSearchIndex(
      await File(tafseerSearchIndexPath()).readAsString(),
    );
    expect(passages, isNotNull);
    expect(passages!.length, greaterThan(20000));
    for (final p in passages) {
      expect(p.folded, foldForSearch(p.text).value);
    }
  });

  test('the index carries every surah and all four match kinds', () async {
    final passages = decodeTafseerSearchIndex(
      await File(tafseerSearchIndexPath()).readAsString(),
    )!;
    expect(passages.map((p) => p.surahNumber).toSet(), hasLength(114));
    expect(
      passages.map((p) => p.kind).toSet(),
      TafseerMatchKind.values.toSet(),
    );
    for (final p in passages.take(500)) {
      expect(p.text.trim(), p.text);
      expect(p.text, isNotEmpty);
      expect(p.rukuNumber, greaterThan(0));
      expect(p.surahId, isNotEmpty);
    }
  });

  test('scanning the content gives exactly the same index', () async {
    final scanned = TafseerSearchService(
      content: TafseerBundledService(bundle: _WithoutSearchIndex()),
    );
    await scanned.buildIndex();
    expect(scanned.usedPrecomputedIndex, isFalse);

    final precomputed = TafseerSearchService();

    // A query per kind, so the comparison covers titles, ayat, glossary and
    // prose rather than whichever one happens to come first.
    for (final query in ['اللہ', 'توحید', 'اعیانِ ثابتہ', 'رب']) {
      final a = await precomputed.search(query, limit: 5000);
      final b = await scanned.search(query, limit: 5000);
      expect(b.length, a.length, reason: query);
      for (var i = 0; i < a.length; i++) {
        expect(b[i].surahId, a[i].surahId, reason: '$query #$i');
        expect(b[i].rukuNumber, a[i].rukuNumber, reason: '$query #$i');
        expect(b[i].kind, a[i].kind, reason: '$query #$i');
        expect(b[i].text, a[i].text, reason: '$query #$i');
        expect(b[i].matchStart, a[i].matchStart, reason: '$query #$i');
        expect(b[i].matchEnd, a[i].matchEnd, reason: '$query #$i');
      }
    }
  });

  test('an unreadable index falls back rather than searching nothing', () {
    expect(decodeTafseerSearchIndex(null), isNull);
    expect(decodeTafseerSearchIndex(''), isNull);
    expect(decodeTafseerSearchIndex('not json'), isNull);
    expect(decodeTafseerSearchIndex('{"version":0}'), isNull);
    // A future format is ignored too, not half-read.
    expect(
      decodeTafseerSearchIndex(
        '{"version":${tafseerSearchIndexVersion + 1},'
        '"kinds":[],"surahs":[],"rukus":[]}',
      ),
      isNull,
    );
  });
}
