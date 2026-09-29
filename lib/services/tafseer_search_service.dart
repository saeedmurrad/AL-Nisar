import '../models/tafseer_search.dart';
import '../utils/arabic_search_text.dart';
import '../utils/tafseer_plain_text.dart';
import 'tafseer_bundled_service.dart';

/// One searchable passage: a paragraph, an ayah, a glossary entry or a title.
class _Passage {
  _Passage({
    required this.surahId,
    required this.surahNameUrdu,
    required this.surahNumber,
    required this.rukuNumber,
    required this.rukuTitle,
    required this.kind,
    required this.text,
  }) : folded = foldForSearch(text);

  final String surahId;
  final String surahNameUrdu;
  final int surahNumber;
  final int rukuNumber;
  final String rukuTitle;
  final TafseerMatchKind kind;
  final String text;
  final SearchText folded;
}

/// Full-text search across every bundled surah.
///
/// The index is built once on the first query — the whole corpus is a little
/// under a megabyte of bundled assets, so there is nothing to gain from a
/// precomputed index file, and this keeps the content the single source.
class TafseerSearchService {
  TafseerSearchService({TafseerBundledService? content})
    : _content = content ?? TafseerBundledService();

  final TafseerBundledService _content;

  List<_Passage>? _index;
  Future<void>? _building;

  bool get isIndexed => _index != null;

  Future<void> buildIndex() {
    if (_index != null) return Future<void>.value();
    return _building ??= _build();
  }

  Future<void> _build() async {
    final passages = <_Passage>[];

    for (final summary in await _content.loadIndex()) {
      final surah = await _content.loadSurah(summary.id);
      if (surah == null) continue;

      for (final ruku in surah.rukus) {
        void add(TafseerMatchKind kind, String text) {
          final trimmed = text.trim();
          if (trimmed.isEmpty) return;
          passages.add(
            _Passage(
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
          add(
            TafseerMatchKind.glossary,
            '${g.term}: ${stripHtml(g.definitionHtml)}',
          );
        }

        final html = await _content.loadRukuHtml(surah.id, ruku.number);
        if (html == null) continue;
        for (final para in _paragraphsOf(html)) {
          add(TafseerMatchKind.commentary, para.prose);
          for (final ayah in para.ayat) {
            add(TafseerMatchKind.ayah, ayah);
          }
        }
      }
    }

    _index = passages;
    _building = null;
  }

  Future<List<TafseerSearchHit>> search(
    String query, {
    String? surahId,
    Set<TafseerMatchKind>? kinds,
    int limit = 200,
  }) async {
    final needle = foldQuery(query);
    if (needle.isEmpty) return const [];

    await buildIndex();
    final index = _index ?? const <_Passage>[];

    final hits = <TafseerSearchHit>[];
    for (final p in index) {
      if (surahId != null && p.surahId != surahId) continue;
      if (kinds != null && kinds.isNotEmpty && !kinds.contains(p.kind)) continue;

      final at = p.folded.value.indexOf(needle);
      if (at < 0) continue;

      hits.add(
        TafseerSearchHit(
          surahId: p.surahId,
          surahNameUrdu: p.surahNameUrdu,
          surahNumber: p.surahNumber,
          rukuNumber: p.rukuNumber,
          rukuTitle: p.rukuTitle,
          kind: p.kind,
          text: p.text,
          matchStart: p.folded.sourceIndex[at],
          matchEnd: p.folded.sourceIndex[at + needle.length],
        ),
      );
      if (hits.length >= limit) break;
    }

    // Ayat and titles first — a reader searching a phrase usually wants the
    // verse itself above the commentary that quotes it.
    const rank = {
      TafseerMatchKind.ayah: 0,
      TafseerMatchKind.title: 1,
      TafseerMatchKind.glossary: 2,
      TafseerMatchKind.commentary: 3,
    };
    hits.sort((a, b) {
      final byKind = rank[a.kind]!.compareTo(rank[b.kind]!);
      if (byKind != 0) return byKind;
      final bySurah = a.surahNumber.compareTo(b.surahNumber);
      if (bySurah != 0) return bySurah;
      return a.rukuNumber.compareTo(b.rukuNumber);
    });
    return hits;
  }

  /// Splits a ruku body into paragraphs, separating the inline ayah fragments
  /// from the prose around them so each can be matched and labelled.
  static List<({String prose, List<String> ayat})> _paragraphsOf(String html) {
    final out = <({String prose, List<String> ayat})>[];
    final paraRe = RegExp(r'<p\b[^>]*>(.*?)</p>', dotAll: true, caseSensitive: false);
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
}
