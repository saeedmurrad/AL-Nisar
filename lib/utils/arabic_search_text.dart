/// Normalised text plus a map back to the original string.
///
/// Searching Urdu and Quranic Arabic only works if diacritics and letter
/// variants are folded away first: a reader typing `نحن نقص` will never match
/// `نَحْنُ نَقُصُّ` byte-for-byte. Folding changes the length, so the index map
/// is what lets a hit be highlighted at the right place in the original.
class SearchText {
  const SearchText(this.value, this.sourceIndex);

  /// The folded text that matching runs against.
  final String value;

  /// `sourceIndex[i]` is the offset in the original string that produced
  /// `value[i]`. Length is `value.length + 1`; the last entry is the end.
  final List<int> sourceIndex;

  bool get isEmpty => value.isEmpty;
}

// Harakat, tanwin, superscript alef, and the Quranic annotation marks.
final _marks = RegExp(
  r'[ً-ٰٟـۖ-ࣰۭ-ࣿ‌‍﻿]',
);

const _folds = <String, String>{
  // Alef forms
  'آ': 'ا', 'أ': 'ا', 'إ': 'ا', 'ٱ': 'ا',
  // Yeh forms — Urdu yeh, Arabic yeh, alef maqsura, bari yeh, hamza-on-yeh
  'ي': 'ی', 'ى': 'ی', 'ے': 'ی', 'ئ': 'ی',
  // Kaf
  'ك': 'ک',
  // Heh — Arabic heh, teh marbuta and heh-goal fold together.
  // Do-chashmi heh (U+06BE) is deliberately NOT folded: it marks Urdu
  // aspirates, and folding it would make بھائی match بہائی.
  'ه': 'ہ', 'ة': 'ہ', 'ۀ': 'ہ',
  // Waw with hamza
  'ؤ': 'و',
};

const _digits = <String, String>{
  '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
  '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
  '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
  '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
};

/// Folds [input] for matching and records where each kept character came from.
SearchText foldForSearch(String input) {
  final buf = StringBuffer();
  final map = <int>[];

  var pendingSpace = false;
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];

    if (_marks.hasMatch(ch)) continue;

    if (ch.trim().isEmpty) {
      // Collapse runs of whitespace to a single space, never leading.
      if (buf.isNotEmpty) pendingSpace = true;
      continue;
    }
    if (pendingSpace) {
      buf.write(' ');
      map.add(i);
      pendingSpace = false;
    }

    final folded = _folds[ch] ?? _digits[ch] ?? ch.toLowerCase();
    buf.write(folded);
    // One map entry per emitted character: toLowerCase can widen a character,
    // and a desynced map would highlight the wrong span.
    for (var k = 0; k < folded.length; k++) {
      map.add(i);
    }
  }

  map.add(input.length);
  return SearchText(buf.toString(), map);
}

/// Folds a query the same way, without needing the index map.
String foldQuery(String query) => foldForSearch(query).value.trim();
