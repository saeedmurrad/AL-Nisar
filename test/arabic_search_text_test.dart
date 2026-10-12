import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/utils/arabic_search_text.dart';

// The folding this file's subject replaced: a regex test and a `toLowerCase`
// per character. It is kept here as the oracle — the rewrite exists only to be
// faster, so any disagreement with it is a bug.
final _refMarks = RegExp('[ً-ٰٟـۖ-ࣰۭ-ࣿ‌‍﻿]');

const _refFolds = <String, String>{
  'آ': 'ا', 'أ': 'ا', 'إ': 'ا', 'ٱ': 'ا', //
  'ي': 'ی', 'ى': 'ی', 'ے': 'ی', 'ئ': 'ی',
  'ك': 'ک',
  'ه': 'ہ', 'ة': 'ہ', 'ۀ': 'ہ',
  'ؤ': 'و',
};

const _refDigits = <String, String>{
  '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4', //
  '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
  '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
  '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
};

({String value, List<int> map}) _reference(String input) {
  final buf = StringBuffer();
  final map = <int>[];

  var pendingSpace = false;
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    if (_refMarks.hasMatch(ch)) continue;
    if (ch.trim().isEmpty) {
      if (buf.isNotEmpty) pendingSpace = true;
      continue;
    }
    if (pendingSpace) {
      buf.write(' ');
      map.add(i);
      pendingSpace = false;
    }
    final folded = _refFolds[ch] ?? _refDigits[ch] ?? ch.toLowerCase();
    buf.write(folded);
    for (var k = 0; k < folded.length; k++) {
      map.add(i);
    }
  }
  map.add(input.length);
  return (value: buf.toString(), map: map);
}

void main() {
  group('foldForSearch matches the reference folding', () {
    test('for every code unit, alone and inside a word', () {
      for (var u = 0; u <= 0xFFFF; u++) {
        for (final input in [
          '${String.fromCharCode(u)}',
          'ا${String.fromCharCode(u)}ا',
        ]) {
          final got = foldForSearch(input);
          final want = _reference(input);
          expect(got.value, want.value, reason: 'U+${u.toRadixString(16)}');
          expect(got.sourceIndex, want.map, reason: 'U+${u.toRadixString(16)}');
        }
      }
    });

    test('for mixed Urdu, Arabic, Latin and digits', () {
      for (final input in const [
        'نَحْنُ نَقُصُّ عَلَيْكَ أَحْسَنَ ٱلْقَصَصِ',
        '  ایک   دو  ',
        'Shaykh al-Akbar ١٢٣ ۴۵۶',
        'TAWHID توحید İstanbul ß',
        'بھائی بہائی',
        '‌زیرو‍ویڈتھ﻿',
        '',
        '   ',
        '\n\t a \r\n b    c',
      ]) {
        final got = foldForSearch(input);
        final want = _reference(input);
        expect(got.value, want.value, reason: input);
        expect(got.sourceIndex, want.map, reason: input);
        expect(foldValueForSearch(input), want.value, reason: input);
      }
    });
  });

  group('foldForSearch', () {
    test('index map stays aligned with the folded text', () {
      for (final input in const [
        'نَحْنُ نَقُصُّ عَلَيْكَ',
        'سورۂ یوسف',
        'a  b\n\nc',
        '',
        'الٓرٰ ۚ تِلْكَ اٰيٰتُ',
      ]) {
        final t = foldForSearch(input);
        expect(
          t.sourceIndex.length,
          t.value.length + 1,
          reason: 'map length for ${input.length} chars',
        );
        for (final idx in t.sourceIndex) {
          expect(idx, inInclusiveRange(0, input.length));
        }
      }
    });

    test('diacritics are folded away so an ayah is findable', () {
      final t = foldForSearch('نَحْنُ نَقُصُّ عَلَيْكَ');
      expect(t.value.contains(foldQuery('نحن نقص')), isTrue);
    });

    test('folds alef, yeh and kaf variants together', () {
      expect(foldQuery('أحمد'), foldQuery('احمد'));
      expect(foldQuery('يوسف'), foldQuery('یوسف'));
      expect(foldQuery('كتاب'), foldQuery('کتاب'));
    });

    test('does NOT fold do-chashmi heh, which would merge distinct words', () {
      // بھائی (brother) must not collapse into بہائی.
      expect(foldQuery('بھائی'), isNot(foldQuery('بہائی')));
    });

    test('folds Urdu and Arabic digits to Western', () {
      expect(foldQuery('۱۲'), '12');
      expect(foldQuery('٣٤'), '34');
    });

    test('collapses whitespace without a leading space', () {
      final t = foldForSearch('  ایک   دو  ');
      expect(t.value, 'ایک دو');
    });

    test('a match maps back to the right slice of the original', () {
      const original = 'یہ نَحْنُ نَقُصُّ ہے';
      final t = foldForSearch(original);
      final at = t.value.indexOf(foldQuery('نحن'));
      expect(at, greaterThan(-1));
      final start = t.sourceIndex[at];
      final end = t.sourceIndex[at + foldQuery('نحن').length];
      expect(
        original.substring(start, end).replaceAll(RegExp(r'\s+$'), ''),
        contains('نَحْنُ'),
      );
    });
  });
}
