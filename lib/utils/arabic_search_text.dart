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

// Harakat, tanwin, superscript alef, tatweel, the Quranic annotation marks,
// and the zero-width joiners — everything a reader never types.
//
// Tested by code unit rather than by regex: folding runs over the whole corpus
// when the search index is read, and a `RegExp.hasMatch` per character was the
// single most expensive thing in that loop.
bool _isMark(int u) =>
    (u >= 0x064B && u <= 0x065F) || // harakat and tanwin
    u == 0x0670 || // superscript alef
    u == 0x0640 || // tatweel
    (u >= 0x06D6 && u <= 0x06ED) || // Quranic annotation marks
    (u >= 0x08F0 && u <= 0x08FF) || // Arabic Extended-A marks
    u == 0x200C || // ZWNJ
    u == 0x200D || // ZWJ
    u == 0xFEFF; // BOM

/// The Unicode White_Space property, which is what `String.trim` matches.
bool _isSpace(int u) =>
    u == 0x20 ||
    (u >= 0x09 && u <= 0x0D) ||
    u == 0x85 ||
    u == 0xA0 ||
    u == 0x1680 ||
    (u >= 0x2000 && u <= 0x200A) ||
    u == 0x2028 ||
    u == 0x2029 ||
    u == 0x202F ||
    u == 0x205F ||
    u == 0x3000;

/// True for the blocks this content is written in, none of which hold a cased
/// character — so a code unit from them is its own lowercase and needs no
/// `toLowerCase` call.
bool _isUncasedArabic(int u) =>
    (u >= 0x0600 && u <= 0x06FF) ||
    (u >= 0x0750 && u <= 0x077F) ||
    (u >= 0x08A0 && u <= 0x08FF) ||
    (u >= 0xFB50 && u <= 0xFDFF) ||
    (u >= 0xFE70 && u <= 0xFEFF);

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
  '۰': '0',
  '۱': '1',
  '۲': '2',
  '۳': '3',
  '۴': '4',
  '۵': '5',
  '۶': '6',
  '۷': '7',
  '۸': '8',
  '۹': '9',
  '٠': '0',
  '١': '1',
  '٢': '2',
  '٣': '3',
  '٤': '4',
  '٥': '5',
  '٦': '6',
  '٧': '7',
  '٨': '8',
  '٩': '9',
};

/// [_folds] and [_digits] keyed by code unit, which is how [_fold] reads them.
final _foldUnits = <int, String>{
  for (final e in _folds.entries) e.key.codeUnitAt(0): e.value,
  for (final e in _digits.entries) e.key.codeUnitAt(0): e.value,
};

/// Folds [input] for matching and records where each kept character came from.
SearchText foldForSearch(String input) {
  final map = <int>[];
  final value = _fold(input, map);
  map.add(input.length);
  return SearchText(value, map);
}

/// The folded text alone, identical to `foldForSearch(input).value`.
///
/// The index map is several integers per character, so building one for the
/// whole corpus just to throw it away is the expensive half of folding. The
/// search index folds tens of thousands of passages to match against and needs
/// a map only for the few a query actually hits.
String foldValueForSearch(String input) => _fold(input, null);

String _fold(String input, List<int>? map) {
  final buf = StringBuffer();

  var pendingSpace = false;
  for (var i = 0; i < input.length; i++) {
    final u = input.codeUnitAt(i);

    if (_isMark(u)) continue;

    if (_isSpace(u)) {
      // Collapse runs of whitespace to a single space, never leading.
      if (buf.isNotEmpty) pendingSpace = true;
      continue;
    }
    if (pendingSpace) {
      buf.write(' ');
      map?.add(i);
      pendingSpace = false;
    }

    final folded = _foldUnit(u);
    if (folded == null) {
      buf.writeCharCode(u);
      map?.add(i);
      continue;
    }
    buf.write(folded);
    // One map entry per emitted character: lowercasing can widen a character,
    // and a desynced map would highlight the wrong span.
    for (var k = 0; k < folded.length; k++) {
      map?.add(i);
    }
  }

  return buf.toString();
}

/// What [u] folds to, or null when it stands for itself.
String? _foldUnit(int u) {
  if (u < 0x80) {
    return (u >= 0x41 && u <= 0x5A) ? _asciiLower[u - 0x41] : null;
  }
  final mapped = _foldUnits[u];
  if (mapped != null) return mapped;
  if (_isUncasedArabic(u)) return null;

  // Anything else — Latin letters in a glossary, a stray accented character.
  final lower = String.fromCharCode(u).toLowerCase();
  return (lower.length == 1 && lower.codeUnitAt(0) == u) ? null : lower;
}

const _asciiLower = [
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', //
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
];

/// Folds a query the same way, without needing the index map.
String foldQuery(String query) => foldValueForSearch(query).trim();
