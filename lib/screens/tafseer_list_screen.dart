import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../models/tafseer_models.dart';
import '../models/tafseer_search.dart';
import '../services/tafseer_bundled_service.dart';
import '../services/tafseer_search_service.dart';
import '../theme/app_layout.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../theme/tafseer_theme.dart';
import '../utils/responsive_layout.dart';
import '../utils/tafseer_surah_filter.dart';
import '../utils/urdu_digits.dart';
import '../widgets/app_drawer.dart';
import '../widgets/branded_state_view.dart';
import '../widgets/gold_card.dart';
import '../widgets/islamic_ui.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/tafseer_search_field.dart';
import '../widgets/tafseer_search_result_card.dart';

/// Tafseer-e-Quran index: the surahs with bundled tafseer.
///
/// The whole Quran is bundled, so this screen has to make 114 surahs findable
/// rather than merely list them. Three things do that: the search box doubles
/// as a surah jump, a strip of ten-surah ranges narrows the grid to a
/// screenful, and the cards sit in a responsive grid instead of one long
/// column — a phone shows one per row, a desktop three.
class TafseerListScreen extends StatefulWidget {
  const TafseerListScreen({super.key, this.service, this.searchService});

  /// Injectable for tests; defaults to the bundled assets.
  final TafseerBundledService? service;
  final TafseerSearchService? searchService;

  @override
  State<TafseerListScreen> createState() => _TafseerListScreenState();
}

class _TafseerListScreenState extends State<TafseerListScreen> {
  late final _service = widget.service ?? TafseerBundledService();
  late final _search =
      widget.searchService ?? TafseerSearchService(content: _service);
  late Future<List<TafseerSurahSummary>> _future;

  /// The resolved index, so a query can name surahs without a FutureBuilder
  /// in the middle of the results list.
  List<TafseerSurahSummary> _all = const [];

  final _queryController = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  String _query = '';
  bool _searching = false;
  List<TafseerSearchHit> _hits = const [];
  final Set<TafseerMatchKind> _kinds = {};
  String? _surahFilter;
  _SurahRange? _range;

  @override
  void initState() {
    super.initState();
    _future = _service.loadIndex();
    _future.then((list) {
      if (mounted) setState(() => _all = list);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    // The index is built on the first query; debounce so a fast typist does
    // not queue a search per keystroke over the whole corpus.
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _query.trim();
    if (q.isEmpty) {
      setState(() {
        _hits = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final hits = await _search.search(
      q,
      surahId: _surahFilter,
      kinds: _kinds.isEmpty ? null : _kinds,
    );
    if (!mounted || _query.trim() != q) return;
    setState(() {
      _hits = hits;
      _searching = false;
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _queryController.clear();
    setState(() {
      _query = '';
      _hits = const [];
      _searching = false;
    });
  }

  void _selectRange(_SurahRange? range) {
    setState(() => _range = range);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  bool get _isSearching => _query.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // The index reads on the same paper as the surahs it opens into; the
    // shell header keeps the app's emerald chrome, as it does in the reader.
    // The palette has to be read from a context *below* this wrapper, hence
    // the Builder — an outer `context.c` would still be the app's own.
    return Theme(
      data: tafseerTheme(context),
      child: Builder(
        builder: (context) {
          final c = context.c;
          return Scaffold(
            backgroundColor: c.backgroundPrimary,
            drawer: ResponsiveLayout.isExpanded(context)
                ? null
                : const AppDrawer(),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StandardShellHeader(title: 'Tafseer-e-Quran'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.md,
                    AppLayout.sm,
                    AppLayout.md,
                    0,
                  ),
                  child: ContentColumn(
                    maxWidth: 720,
                    child: TafseerSearchField(
                      controller: _queryController,
                      onChanged: _onQueryChanged,
                      onClear: _clearSearch,
                    ),
                  ),
                ),
                // The ranges stay put while the grid scrolls — on a phone,
                // scrolling back to the top of 114 surahs to change filter is
                // the whole problem this strip exists to solve.
                if (!_isSearching)
                  _SurahRangeStrip(
                    surahs: _all,
                    selected: _range,
                    onSelected: _selectRange,
                  ),
                Expanded(
                  child: _isSearching ? _buildResults() : _buildBrowse(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- browse

  Widget _buildBrowse() {
    return FutureBuilder<List<TafseerSurahSummary>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const BrandedStateView(
            icon: Icons.auto_stories_outlined,
            title: 'Loading Tafseer-e-Quran',
            loading: true,
          );
        }
        final surahs = snap.data ?? const <TafseerSurahSummary>[];
        if (surahs.isEmpty) {
          return const BrandedStateView(
            icon: Icons.auto_stories_outlined,
            title: 'No tafseer yet',
            message: 'Tafseer will appear here as it is published.',
          );
        }

        final range = _range;
        final shown = range == null
            ? surahs
            : surahs.where(range.contains).toList();

        return LayoutBuilder(
          builder: (context, box) {
            final columns = _columnsFor(box.maxWidth);
            final inset = _sideInsetFor(box.maxWidth, columns);

            return CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: _Masthead(surahs: surahs, shown: shown.length),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: inset),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 92,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _SurahCard(summary: shown[i]),
                      childCount: shown.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppLayout.lg)),
                const SliverToBoxAdapter(child: AppFooter()),
              ],
            );
          },
        );
      },
    );
  }

  /// One card per row on a phone — an Urdu name beside a number badge needs
  /// the width — then two on a tablet, three on a desktop, four on a large
  /// monitor.
  ///
  /// These read the content width, not the window: the desktop shell keeps a
  /// 264px side nav, so a 1440px window leaves 1176px here and must still be
  /// treated as a three-column desktop.
  static int _columnsFor(double width) {
    if (width >= 1560) return 4;
    if (width >= 1040) return 3;
    if (width >= ResponsiveLayout.mediumWidth) return 2;
    return 1;
  }

  /// Side padding that both insets the grid and centres it once the viewport
  /// is wider than the column count needs.
  static double _sideInsetFor(double width, int columns) {
    const cap = {1: 640.0, 2: 980.0, 3: 1320.0, 4: 1680.0};
    final maxWidth = cap[columns]!;
    final slack = width - maxWidth;
    return AppLayout.md + (slack > 0 ? slack / 2 : 0);
  }

  // --------------------------------------------------------------- results

  Widget _buildResults() {
    if (_searching) {
      return const BrandedStateView(
        icon: Icons.search_rounded,
        title: 'Searching',
        loading: true,
      );
    }

    final named = tafseerSurahsMatching(_all, _query);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.md,
        AppLayout.md,
        AppLayout.md,
        24,
      ),
      children: [
        ContentColumn(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A query that names a surah is a request to go there, so those
              // come first — above the passages that merely quote the words,
              // and above the filters, which only narrow the passages.
              if (named.isNotEmpty) ...[
                const _ResultsLabel('Surahs'),
                for (final s in named) ...[
                  _SurahCard(summary: s),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: AppLayout.md),
              ],
              _FilterBar(
                kinds: _kinds,
                surahFilter: _surahFilter,
                surahs: _future,
                onKindToggled: (k) {
                  setState(() {
                    if (!_kinds.remove(k)) _kinds.add(k);
                  });
                  _runSearch();
                },
                onSurahChanged: (id) {
                  setState(() => _surahFilter = id);
                  _runSearch();
                },
              ),
              const SizedBox(height: AppLayout.md),
              if (_hits.isEmpty && named.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: BrandedStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message:
                        'Nothing found for “${_query.trim()}”. Try fewer words, '
                        'or clear the filters.',
                  ),
                )
              else if (_hits.isNotEmpty) ...[
                _ResultsLabel(
                  _hits.length == 1 ? '1 passage' : '${_hits.length} passages',
                ),
                for (final hit in _hits)
                  TafseerSearchResultCard(
                    hit: hit,
                    onTap: () => context.go(hit.route),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A ten-surah band of the Quran, e.g. `۳۱–۴۰`.
class _SurahRange {
  const _SurahRange(this.from, this.to);

  final int from;
  final int to;

  bool contains(TafseerSurahSummary s) =>
      s.surahNumber >= from && s.surahNumber <= to;

  String get label => '${toUrduDigits(from)}–${toUrduDigits(to)}';

  @override
  bool operator ==(Object other) =>
      other is _SurahRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Horizontally scrolling ranges that cut 114 surahs down to a screenful.
class _SurahRangeStrip extends StatelessWidget {
  const _SurahRangeStrip({
    required this.surahs,
    required this.selected,
    required this.onSelected,
  });

  final List<TafseerSurahSummary> surahs;
  final _SurahRange? selected;
  final ValueChanged<_SurahRange?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (surahs.length < 20) return const SizedBox.shrink();

    final last = surahs.last.surahNumber;
    final ranges = <_SurahRange>[
      for (var from = 1; from <= last; from += 10)
        _SurahRange(from, from + 9 > last ? last : from + 9),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppLayout.md),
          children: [
            TafseerFilterChip(
              label: 'سب  ·  All',
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final r in ranges) ...[
              const SizedBox(width: 8),
              TafseerFilterChip(
                label: r.label,
                selected: selected == r,
                onTap: () => onSelected(selected == r ? null : r),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The page masthead.
///
/// A phone gets a shorter one — the full ornamental header is most of a small
/// screen, and a reader who opened Tafseer to find a surah should see surahs
/// without scrolling past a title that repeats the one already in the bar.
class _Masthead extends StatelessWidget {
  const _Masthead({required this.surahs, required this.shown});

  final List<TafseerSurahSummary> surahs;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final narrow =
        ResponsiveLayout.screenWidth(context) < ResponsiveLayout.mediumWidth;

    if (!narrow) {
      return Column(
        children: [
          const SizedBox(height: AppLayout.lg),
          const SectionHeader(
            caption: 'Tafseer-e-Quran',
            title: 'Ishari Tafseer',
            urdu: 'اشاری تفسیر',
          ),
          const SizedBox(height: 12),
          _CorpusLine(surahs: surahs, shown: shown),
          const SizedBox(height: AppLayout.lg),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 14),
        Text(
          'Ishari Tafseer',
          textAlign: TextAlign.center,
          style: AppTheme.cormorantGaramond(
            fontSize: 21,
            color: c.textPrimary,
            letterSpacing: 0.6,
          ),
        ),
        Text(
          'اشاری تفسیر',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTheme.amiriUrdu(
            fontSize: 13,
            color: c.textMuted,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 6),
        _CorpusLine(surahs: surahs, shown: shown),
        const SizedBox(height: 14),
      ],
    );
  }
}

/// The tally under the masthead: what is bundled, and what the strip is
/// currently showing of it.
class _CorpusLine extends StatelessWidget {
  const _CorpusLine({required this.surahs, required this.shown});

  final List<TafseerSurahSummary> surahs;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final rukus = surahs.fold<int>(0, (sum, s) => sum + s.rukuCount);
    final all = shown == surahs.length;
    final text = all
        ? '${surahs.length} surahs  ·  $rukus rukus'
        : '$shown of ${surahs.length} surahs';

    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTheme.lato(
        fontSize: 12,
        letterSpacing: 0.6,
        color: context.c.textMuted,
      ),
    );
  }
}

/// A small gold caption separating one block of results from the next.
class _ResultsLabel extends StatelessWidget {
  const _ResultsLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.sectionCaption(
          color: context.c.accentGold,
          fontSize: 10,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

/// Result-type chips plus a surah narrowing dropdown.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.kinds,
    required this.surahFilter,
    required this.surahs,
    required this.onKindToggled,
    required this.onSurahChanged,
  });

  final Set<TafseerMatchKind> kinds;
  final String? surahFilter;
  final Future<List<TafseerSurahSummary>> surahs;
  final ValueChanged<TafseerMatchKind> onKindToggled;
  final ValueChanged<String?> onSurahChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TafseerFilterChip(
              label: 'All',
              selected: kinds.isEmpty,
              onTap: () {
                for (final k in TafseerMatchKind.values.toList()) {
                  if (kinds.contains(k)) onKindToggled(k);
                }
              },
            ),
            for (final k in TafseerMatchKind.values)
              TafseerFilterChip(
                label: k.label,
                selected: kinds.contains(k),
                onTap: () => onKindToggled(k),
              ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<TafseerSurahSummary>>(
          future: surahs,
          builder: (context, snap) {
            final list = snap.data ?? const <TafseerSurahSummary>[];
            if (list.isEmpty) return const SizedBox.shrink();
            return Row(
              children: [
                Text(
                  'Surah',
                  style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String?>(
                    value: surahFilter,
                    isExpanded: true,
                    underline: Container(height: 1, color: c.borderDefault),
                    style: AppTheme.lato(fontSize: 13, color: c.textPrimary),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'All surahs',
                          style: AppTheme.lato(
                            fontSize: 13,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      for (final s in list)
                        DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(
                            s.nameUrdu,
                            style: AppTheme.lato(
                              fontSize: 13,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                    ],
                    onChanged: onSurahChanged,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One surah, sized to tile: badge, Urdu name, ruku tally.
///
/// The `تفسیرِ ابنِ عربی` line every card used to carry is gone — it is the
/// same on all 114 and says nothing about this surah, so it belongs in the
/// masthead, not repeated down the page.
class _SurahCard extends StatelessWidget {
  const _SurahCard({required this.summary});

  final TafseerSurahSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final enabled = summary.isAvailable;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppLayout.cardRadius,
          hoverColor: c.accentGold.o(0.05),
          onTap: enabled ? () => context.go('/tafseer/${summary.id}') : null,
          child: GoldCard(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              children: [
                _SurahNumberBadge(number: summary.surahNumber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          summary.nameUrdu,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.amiriUrdu(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                            // Urdu names carry marks that rise well above the
                            // letters — یٰسٓ has two — so the line box has to
                            // leave them room or they touch the card edge.
                            height: 1.95,
                          ),
                        ),
                      ),
                      Text(
                        enabled
                            // The short surahs near the end of the Quran have
                            // a single ruku, so the noun has to agree.
                            ? '${summary.rukuCount} '
                                  '${summary.rukuCount == 1 ? 'ruku' : 'rukus'}'
                                  ' · Urdu'
                            : 'Coming soon',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.lato(
                          fontSize: 11.5,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: c.accentGold.o(0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahNumberBadge extends StatelessWidget {
  const _SurahNumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.accentGold.o(0.14),
        border: Border.all(color: c.accentGold.o(0.85), width: 1.2),
      ),
      child: Text(
        toUrduDigits(number),
        style: AppTheme.amiriUrdu(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: c.accentGold,
          height: 1.2,
        ),
      ),
    );
  }
}
