/// Which part of a ruku a hit came from — drives the result filters.
enum TafseerMatchKind { ayah, commentary, glossary, title }

extension TafseerMatchKindX on TafseerMatchKind {
  /// Filter-chip label, in Urdu to match the content.
  String get label => switch (this) {
    TafseerMatchKind.ayah => 'آیات',
    TafseerMatchKind.commentary => 'تفسیر',
    TafseerMatchKind.glossary => 'لغات',
    TafseerMatchKind.title => 'عنوان',
  };
}

/// One search result: where it is, and enough text to show it in context.
class TafseerSearchHit {
  const TafseerSearchHit({
    required this.surahId,
    required this.surahNameUrdu,
    required this.surahNumber,
    required this.rukuNumber,
    required this.rukuTitle,
    required this.kind,
    required this.text,
    required this.matchStart,
    required this.matchEnd,
  });

  final String surahId;
  final String surahNameUrdu;
  final int surahNumber;
  final int rukuNumber;
  final String rukuTitle;
  final TafseerMatchKind kind;

  /// The passage the match sits in, unmodified.
  final String text;

  /// Match bounds as offsets into [text].
  final int matchStart;
  final int matchEnd;

  String get route => '/tafseer/$surahId/$rukuNumber';

  /// A window of [text] around the match, with the match's offsets rebased.
  ({String text, int start, int end}) snippet({int context = 70}) {
    var from = matchStart - context;
    var to = matchEnd + context;
    if (from < 0) from = 0;
    if (to > text.length) to = text.length;

    // Avoid cutting inside a surrogate pair.
    while (from > 0 && _isLowSurrogate(text.codeUnitAt(from))) {
      from--;
    }
    while (to < text.length && _isLowSurrogate(text.codeUnitAt(to))) {
      to++;
    }

    final lead = from > 0 ? '… ' : '';
    final tail = to < text.length ? ' …' : '';
    return (
      text: '$lead${text.substring(from, to)}$tail',
      start: lead.length + (matchStart - from),
      end: lead.length + (matchEnd - from),
    );
  }

  static bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
}
