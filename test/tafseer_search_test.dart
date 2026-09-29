import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/models/tafseer_search.dart';
import 'package:spiritual_learning_app/services/tafseer_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final search = TafseerSearchService();

  test('finds an ayah typed without diacritics', () async {
    final hits = await search.search('نحن نقص');
    expect(hits, isNotEmpty);
    final h = hits.first;
    expect(h.kind, TafseerMatchKind.ayah);
    expect(h.surahId, 'yusuf');
    expect(h.text, contains('نَحْنُ'));
    // The recorded bounds point at the real ayah inside the original text.
    expect(h.text.substring(h.matchStart, h.matchEnd), contains('نَحْن'));
  });

  test('finds a glossary term and reports it as glossary', () async {
    final hits = await search.search('اعیانِ ثابتہ',
        kinds: {TafseerMatchKind.glossary});
    expect(hits, isNotEmpty);
    expect(hits.every((h) => h.kind == TafseerMatchKind.glossary), isTrue);
  });

  test('finds prose and links to a real ruku', () async {
    final hits = await search.search('شیخِ اکبر',
        kinds: {TafseerMatchKind.commentary});
    expect(hits, isNotEmpty);
    for (final h in hits.take(20)) {
      expect(h.rukuNumber, greaterThan(0));
      expect(h.route, '/tafseer/${h.surahId}/${h.rukuNumber}');
    }
  });

  test('surah filter narrows results to one surah', () async {
    final all = await search.search('رب');
    final one = await search.search('رب', surahId: 'kahf');
    expect(one, isNotEmpty);
    expect(one.every((h) => h.surahId == 'kahf'), isTrue);
    expect(one.length, lessThan(all.length));
  });

  test('kind filter is respected', () async {
    final hits = await search.search('اللہ', kinds: {TafseerMatchKind.ayah});
    expect(hits, isNotEmpty);
    expect(hits.every((h) => h.kind == TafseerMatchKind.ayah), isTrue);
  });

  test('ayat and titles rank above commentary', () async {
    final hits = await search.search('کہف');
    expect(hits, isNotEmpty);
    final kinds = hits.map((h) => h.kind).toList();
    const rank = {
      TafseerMatchKind.ayah: 0,
      TafseerMatchKind.title: 1,
      TafseerMatchKind.glossary: 2,
      TafseerMatchKind.commentary: 3,
    };
    for (var i = 1; i < kinds.length; i++) {
      expect(rank[kinds[i]]!, greaterThanOrEqualTo(rank[kinds[i - 1]]!));
    }
  });

  test('empty or whitespace query returns nothing', () async {
    expect(await search.search(''), isEmpty);
    expect(await search.search('   '), isEmpty);
  });

  test('a word that appears nowhere returns nothing', () async {
    expect(await search.search('zzzqqqxx'), isEmpty);
  });

  test('snippet keeps the match inside its own bounds', () async {
    final hits = await search.search('توحید');
    expect(hits, isNotEmpty);
    for (final h in hits.take(30)) {
      final s = h.snippet();
      expect(s.start, lessThan(s.end));
      expect(s.end, lessThanOrEqualTo(s.text.length));
      expect(s.text.substring(s.start, s.end).isNotEmpty, isTrue);
    }
  });

  test('index covers every bundled surah', () async {
    final hits = await search.search('اللہ', limit: 5000);
    expect(hits.map((h) => h.surahId).toSet().length, greaterThanOrEqualTo(7));
  });
}
