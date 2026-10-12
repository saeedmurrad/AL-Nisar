import 'dart:convert';

import '../models/tafseer_search.dart';
import 'tafseer_passages.dart';

/// Format version of `assets/tafseer/search-index.json`.
///
/// Bumped whenever the shape below changes. A reader that meets a version it
/// does not know falls back to scanning the content, so an index left behind
/// by an older build is ignored rather than mis-read.
const tafseerSearchIndexVersion = 1;

/// Serialises [passages] into the bundled search index.
///
/// The shape is deliberately tabular rather than a list of objects: with 114
/// surahs and 558 rukus behind some forty thousand passages, repeating field
/// names and the surah's id, name and number on every row costs megabytes.
///
/// ```json
/// {
///   "version": 1,
///   "kinds":   ["ayah", "commentary", ...],
///   "surahs":  [["fatihah", "سورۂ فاتحہ", 1], ...],
///   "rukus":   [[surahIndex, rukuNumber, "ruku title",
///                [[kindIndex, "text"], ...]], ...]
/// }
/// ```
///
/// The folded form each passage is matched against is *not* stored: it is
/// nearly as long as the text itself, and shipping both would make the index
/// larger over the wire than the content it replaces. Folding on load is the
/// cheap half of the work the index exists to avoid — the expensive half is
/// the 673 asset reads and the HTML parsing, and those are gone.
String encodeTafseerSearchIndex(List<TafseerPassage> passages) {
  final kinds = TafseerMatchKind.values.map((k) => k.name).toList();
  final kindIndex = {
    for (var i = 0; i < TafseerMatchKind.values.length; i++)
      TafseerMatchKind.values[i]: i,
  };

  final surahs = <List<dynamic>>[];
  final surahIndex = <String, int>{};
  final rukus = <List<dynamic>>[];
  List<dynamic>? rows;
  String? currentRuku;

  for (final p in passages) {
    final si = surahIndex.putIfAbsent(p.surahId, () {
      surahs.add([p.surahId, p.surahNameUrdu, p.surahNumber]);
      return surahs.length - 1;
    });

    final key = '${p.surahId}/${p.rukuNumber}';
    if (key != currentRuku) {
      currentRuku = key;
      rows = <dynamic>[];
      rukus.add([si, p.rukuNumber, p.rukuTitle, rows]);
    }
    rows!.add([kindIndex[p.kind], p.text]);
  }

  return jsonEncode({
    'version': tafseerSearchIndexVersion,
    'kinds': kinds,
    'surahs': surahs,
    'rukus': rukus,
  });
}

/// Reads an index back, or returns null if it is absent, malformed, or of a
/// version this build does not understand — every one of which means "scan the
/// content instead", never "the corpus is empty".
List<TafseerPassage>? decodeTafseerSearchIndex(String? json) {
  if (json == null || json.isEmpty) return null;
  try {
    final root = jsonDecode(json);
    if (root is! Map<String, dynamic>) return null;
    if (root['version'] != tafseerSearchIndexVersion) return null;

    final kinds = (root['kinds'] as List<dynamic>)
        .map((k) => TafseerMatchKind.values.byName(k.toString()))
        .toList();
    final surahs = (root['surahs'] as List<dynamic>).cast<List<dynamic>>();

    final out = <TafseerPassage>[];
    for (final ruku in (root['rukus'] as List<dynamic>)) {
      final r = ruku as List<dynamic>;
      final surah = surahs[r[0] as int];
      final number = (r[1] as num).toInt();
      final title = r[2].toString();

      for (final row in (r[3] as List<dynamic>)) {
        final p = row as List<dynamic>;
        out.add(
          TafseerPassage(
            surahId: surah[0].toString(),
            surahNameUrdu: surah[1].toString(),
            surahNumber: (surah[2] as num).toInt(),
            rukuNumber: number,
            rukuTitle: title,
            kind: kinds[p[0] as int],
            text: p[1].toString(),
          ),
        );
      }
    }
    return out;
  } catch (_) {
    return null;
  }
}
