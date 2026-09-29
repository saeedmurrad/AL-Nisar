import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/utils/arabic_search_text.dart';

void main() {
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
        expect(t.sourceIndex.length, t.value.length + 1,
            reason: 'map length for ${input.length} chars');
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
      expect(original.substring(start, end).replaceAll(RegExp(r'\s+$'), ''),
          contains('نَحْنُ'));
    });
  });
}
