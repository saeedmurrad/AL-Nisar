import '../models/tafseer_search.dart';
import '../utils/arabic_search_text.dart';
import '../utils/tafseer_passages.dart';
import '../utils/tafseer_search_index.dart';
import 'tafseer_bundled_service.dart';

/// Full-text search across every bundled surah.
///
/// The index is `assets/tafseer/search-index.json`, precomputed by
/// `tool/build_tafseer_search_index.dart`: reading the corpus itself would
/// mean 673 asset loads and parsing 14MB of HTML before the first query could
/// answer. If that file is missing — an older bundle, or a test with its own
/// asset bundle — the same passages are scanned out of the content instead,
/// which is slower but identical.
class TafseerSearchService {
  TafseerSearchService({TafseerBundledService? content})
    : _content = content ?? TafseerBundledService();

  final TafseerBundledService _content;

  List<TafseerPassage>? _index;
  Future<void>? _building;

  /// Whether the last build read the precomputed index rather than scanning.
  bool get usedPrecomputedIndex => _usedPrecomputed;
  bool _usedPrecomputed = false;

  bool get isIndexed => _index != null;

  Future<void> buildIndex() {
    if (_index != null) return Future<void>.value();
    return _building ??= _build();
  }

  Future<void> _build() async {
    final precomputed = decodeTafseerSearchIndex(
      await _content.loadSearchIndexJson(),
    );
    _usedPrecomputed = precomputed != null;
    _index = precomputed ?? await _scanContent();
    _building = null;
  }

  /// Rebuilds the passages from the content, for when the index is absent.
  Future<List<TafseerPassage>> _scanContent() async {
    final passages = <TafseerPassage>[];
    for (final summary in await _content.loadIndex()) {
      final surah = await _content.loadSurah(summary.id);
      if (surah == null) continue;
      for (final ruku in surah.rukus) {
        final html = await _content.loadRukuHtml(surah.id, ruku.number);
        passages.addAll(
          tafseerRukuPassages(surah: surah, ruku: ruku, bodyHtml: html ?? ''),
        );
      }
    }
    return passages;
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
    final index = _index ?? const <TafseerPassage>[];

    final hits = <TafseerSearchHit>[];
    for (final p in index) {
      if (surahId != null && p.surahId != surahId) continue;
      if (kinds != null && kinds.isNotEmpty && !kinds.contains(p.kind)) {
        continue;
      }

      final at = p.folded.indexOf(needle);
      if (at < 0) continue;

      // Only a hit needs the map back into the original text, so it is built
      // here rather than kept for every passage in the corpus.
      final folded = foldForSearch(p.text);

      hits.add(
        TafseerSearchHit(
          surahId: p.surahId,
          surahNameUrdu: p.surahNameUrdu,
          surahNumber: p.surahNumber,
          rukuNumber: p.rukuNumber,
          rukuTitle: p.rukuTitle,
          kind: p.kind,
          text: p.text,
          matchStart: folded.sourceIndex[at],
          matchEnd: folded.sourceIndex[at + needle.length],
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
}
