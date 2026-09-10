/// Models for the bundled Tafseer content (assets/tafseer/**).
///
/// The content is authored as JSON + HTML assets and shipped with the app,
/// mirroring the Shajra Pak pattern in [ShajraBundledService]. Nothing here
/// touches Firestore.
library;

/// A surah listed on the Tafseer index screen.
class TafseerSurahSummary {
  const TafseerSurahSummary({
    required this.id,
    required this.surahNumber,
    required this.nameUrdu,
    required this.titleUrdu,
    required this.subtitleUrdu,
    required this.rukuCount,
    required this.isAvailable,
  });

  final String id;
  final int surahNumber;
  final String nameUrdu;
  final String titleUrdu;
  final String subtitleUrdu;
  final int rukuCount;
  final bool isAvailable;

  factory TafseerSurahSummary.fromJson(Map<String, dynamic> json) {
    return TafseerSurahSummary(
      id: (json['id'] ?? '').toString(),
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
      nameUrdu: (json['nameUrdu'] ?? '').toString(),
      titleUrdu: (json['titleUrdu'] ?? '').toString(),
      subtitleUrdu: (json['subtitleUrdu'] ?? '').toString(),
      rukuCount: (json['rukuCount'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}

/// One entry in the preface's symbol key (تمثیل کی کلید).
class TafseerKeyEntry {
  const TafseerKeyEntry({required this.term, required this.meaning});

  final String term;
  final String meaning;

  factory TafseerKeyEntry.fromJson(Map<String, dynamic> json) => TafseerKeyEntry(
    term: (json['term'] ?? '').toString(),
    meaning: (json['meaning'] ?? '').toString(),
  );
}

/// One term in a ruku's لغات panel. [definitionHtml] may contain `<b>`.
class TafseerGlossaryEntry {
  const TafseerGlossaryEntry({required this.term, required this.definitionHtml});

  final String term;
  final String definitionHtml;

  factory TafseerGlossaryEntry.fromJson(Map<String, dynamic> json) =>
      TafseerGlossaryEntry(
        term: (json['term'] ?? '').toString(),
        definitionHtml: (json['definitionHtml'] ?? '').toString(),
      );
}

/// A single ruku's front matter. The prose body lives in a separate HTML asset
/// loaded on demand by [TafseerBundledService.loadRukuHtml].
class TafseerRuku {
  const TafseerRuku({
    required this.number,
    required this.ordinalUrdu,
    required this.ayahRangeUrdu,
    required this.titleUrdu,
    required this.ayahBlock,
    required this.glossary,
  });

  final int number;
  final String ordinalUrdu;
  final String ayahRangeUrdu;
  final String titleUrdu;
  final String ayahBlock;
  final List<TafseerGlossaryEntry> glossary;

  /// e.g. `پہلا رکوع · آیات ۱ تا ۶`
  String get eyebrow => ayahRangeUrdu.isEmpty
      ? ordinalUrdu
      : '$ordinalUrdu · آیات $ayahRangeUrdu';

  factory TafseerRuku.fromJson(Map<String, dynamic> json) => TafseerRuku(
    number: (json['number'] as num?)?.toInt() ?? 0,
    ordinalUrdu: (json['ordinalUrdu'] ?? '').toString(),
    ayahRangeUrdu: (json['ayahRangeUrdu'] ?? '').toString(),
    titleUrdu: (json['titleUrdu'] ?? '').toString(),
    ayahBlock: (json['ayahBlock'] ?? '').toString(),
    glossary: ((json['glossary'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TafseerGlossaryEntry.fromJson)
        .toList(),
  );
}

/// A full surah: masthead, preface, symbol key, ruku index and colophon.
class TafseerSurah {
  const TafseerSurah({
    required this.id,
    required this.surahNumber,
    required this.nameUrdu,
    required this.titleUrdu,
    required this.basmala,
    required this.subtitleUrdu,
    required this.kicker,
    required this.prefaceHtml,
    required this.key,
    required this.colophonHtml,
    required this.rukus,
  });

  final String id;
  final int surahNumber;
  final String nameUrdu;
  final String titleUrdu;
  final String basmala;
  final String subtitleUrdu;
  final String kicker;
  final List<String> prefaceHtml;
  final List<TafseerKeyEntry> key;
  final String colophonHtml;
  final List<TafseerRuku> rukus;

  TafseerRuku? rukuByNumber(int number) {
    for (final r in rukus) {
      if (r.number == number) return r;
    }
    return null;
  }

  factory TafseerSurah.fromJson(Map<String, dynamic> json) {
    final rukus =
        ((json['rukus'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TafseerRuku.fromJson)
            .where((r) => r.number > 0)
            .toList()
          ..sort((a, b) => a.number.compareTo(b.number));

    return TafseerSurah(
      id: (json['id'] ?? '').toString(),
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
      nameUrdu: (json['nameUrdu'] ?? '').toString(),
      titleUrdu: (json['titleUrdu'] ?? '').toString(),
      basmala: (json['basmala'] ?? '').toString(),
      subtitleUrdu: (json['subtitleUrdu'] ?? '').toString(),
      kicker: (json['kicker'] ?? '').toString(),
      prefaceHtml: ((json['prefaceHtml'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      key: ((json['key'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TafseerKeyEntry.fromJson)
          .toList(),
      colophonHtml: (json['colophonHtml'] ?? '').toString(),
      rukus: rukus,
    );
  }
}
