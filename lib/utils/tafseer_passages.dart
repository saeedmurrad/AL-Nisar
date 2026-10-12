import '../models/tafseer_models.dart';
import '../models/tafseer_search.dart';
import 'arabic_search_text.dart';
import 'tafseer_plain_text.dart';

/// One searchable passage: a paragraph, an ayah, a glossary entry or a title.
///
/// [folded] is what matching runs against. The map from folded offsets back
/// into [text] is *not* kept — it is several integers per character, which
/// would dwarf the text itself. A query folds only the handful of passages it
/// actually hits, to place the highlight.
class TafseerPassage {
  TafseerPassage({
    required this.surahId,
    required this.surahNameUrdu,
    required this.surahNumber,
    required this.rukuNumber,
    required this.rukuTitle,
    required this.kind,
    required this.text,
  }) : folded = foldValueForSearch(text);

  final String surahId;
  final String surahNameUrdu;
  final int surahNumber;
  final int rukuNumber;
  final String rukuTitle;
  final TafseerMatchKind kind;
  final String text;
  final String folded;
}

/// Every passage one ruku contributes, in index order.
///
/// This is the one definition of "what is searchable". The build-time index
/// generator and the runtime fallback both call it, so a precomputed index can
/// never disagree with a freshly scanned one.
List<TafseerPassage> tafseerRukuPassages({
  required TafseerSurah surah,
  required TafseerRuku ruku,
  required String bodyHtml,
}) {
  final out = <TafseerPassage>[];

  void add(TafseerMatchKind kind, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    out.add(
      TafseerPassage(
        surahId: surah.id,
        surahNameUrdu: surah.nameUrdu,
        surahNumber: surah.surahNumber,
        rukuNumber: ruku.number,
        rukuTitle: ruku.titleUrdu,
        kind: kind,
        text: trimmed,
      ),
    );
  }

  add(TafseerMatchKind.title, ruku.titleUrdu);
  add(TafseerMatchKind.ayah, ruku.ayahBlock);
  for (final g in ruku.glossary) {
    add(TafseerMatchKind.glossary, '${g.term}: ${stripHtml(g.definitionHtml)}');
  }

  for (final para in tafseerBodyParagraphs(bodyHtml)) {
    add(TafseerMatchKind.commentary, para.prose);
    for (final ayah in para.ayat) {
      add(TafseerMatchKind.ayah, ayah);
    }
  }

  return out;
}

/// Splits a ruku body into paragraphs, separating the inline ayah fragments
/// from the prose around them so each can be matched and labelled.
List<({String prose, List<String> ayat})> tafseerBodyParagraphs(String html) {
  final out = <({String prose, List<String> ayat})>[];
  final paraRe = RegExp(
    r'<p\b[^>]*>(.*?)</p>',
    dotAll: true,
    caseSensitive: false,
  );
  final ayahRe = RegExp(
    r'<span[^>]*class="[^"]*\bayah\b[^"]*"[^>]*>(.*?)</span>',
    dotAll: true,
    caseSensitive: false,
  );

  for (final m in paraRe.allMatches(html)) {
    final inner = m.group(1) ?? '';
    final ayat = ayahRe
        .allMatches(inner)
        .map((a) => stripHtml(a.group(1) ?? ''))
        .where((a) => a.isNotEmpty)
        .toList();
    out.add((prose: stripHtml(inner), ayat: ayat));
  }
  return out;
}
