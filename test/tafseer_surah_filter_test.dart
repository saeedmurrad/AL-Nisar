import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/models/tafseer_models.dart';
import 'package:spiritual_learning_app/services/tafseer_bundled_service.dart';
import 'package:spiritual_learning_app/utils/tafseer_surah_filter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<TafseerSurahSummary> surahs;
  setUpAll(() async => surahs = await TafseerBundledService().loadIndex());

  List<String> ids(String query) =>
      tafseerSurahsMatching(surahs, query).map((s) => s.id).toList();

  test('a Latin spelling finds the surah', () {
    expect(ids('yasin'), ['yasin']);
    expect(ids('kahf'), ['kahf']);
    expect(ids('Yusuf'), ['yusuf']);
  });

  test('a hyphenated id is reachable with a space', () {
    expect(ids('bani israel'), ['bani-israel']);
    expect(ids('bani-israel'), ['bani-israel']);
  });

  test('the Urdu name finds it, diacritics or not', () {
    expect(ids('یوسف'), contains('yusuf'));
    expect(ids('الکہف'), ['kahf']);
  });

  test('a number is matched exactly, not as a prefix', () {
    expect(ids('36'), ['yasin']);
    expect(ids('1'), ['fatihah']);
    expect(ids('114'), ['nas']);
    // Urdu-Indic numerals fold to the same thing.
    expect(ids('۳۶'), ['yasin']);
  });

  test('a single letter is treated as the start of typing, not a filter', () {
    expect(ids('a'), isEmpty);
    expect(ids('ا'), isEmpty);
  });

  test('an empty or unmatched query finds nothing', () {
    expect(ids(''), isEmpty);
    expect(ids('   '), isEmpty);
    expect(ids('zzzqqqxx'), isEmpty);
  });

  test('matches come back in surah order', () {
    final hits = tafseerSurahsMatching(surahs, 'al');
    expect(hits, isNotEmpty);
    final numbers = hits.map((s) => s.surahNumber).toList();
    expect(numbers, List<int>.from(numbers)..sort());
  });
}
