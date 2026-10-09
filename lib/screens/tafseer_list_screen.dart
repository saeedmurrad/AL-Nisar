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
import '../utils/responsive_layout.dart';
import '../utils/urdu_digits.dart';
import '../widgets/app_drawer.dart';
import '../widgets/branded_state_view.dart';
import '../widgets/gold_card.dart';
import '../widgets/islamic_ui.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/tafseer_search_field.dart';
import '../widgets/tafseer_search_result_card.dart';

/// Tafseer index: the surahs with bundled commentary.
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

  final _queryController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _searching = false;
  List<TafseerSearchHit> _hits = const [];
  final Set<TafseerMatchKind> _kinds = {};
  String? _surahFilter;

  @override
  void initState() {
    super.initState();
    _future = _service.loadIndex();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      drawer: ResponsiveLayout.isExpanded(context) ? null : const AppDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StandardShellHeader(title: 'Tafseer'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.md,
              AppLayout.md,
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
          Expanded(
            child: _query.trim().isEmpty ? _buildSurahList() : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList() {
    return FutureBuilder<List<TafseerSurahSummary>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const BrandedStateView(
            icon: Icons.auto_stories_outlined,
            title: 'Loading tafseer',
            loading: true,
          );
        }
        final surahs = snap.data ?? const <TafseerSurahSummary>[];
        if (surahs.isEmpty) {
          return const BrandedStateView(
            icon: Icons.auto_stories_outlined,
            title: 'No tafseer yet',
            message: 'Commentary will appear here as it is published.',
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            const SizedBox(height: AppLayout.lg),
            const SectionHeader(
              caption: 'Tafseer',
              title: 'Ishari Commentary',
              urdu: 'اشاری تفسیر',
            ),
            const SizedBox(height: AppLayout.lg),
            ContentColumn(
              maxWidth: 720,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppLayout.md),
                child: Column(
                  children: [
                    for (final s in surahs) ...[
                      _SurahCard(summary: s),
                      const SizedBox(height: AppLayout.md),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppLayout.lg),
            const AppFooter(),
          ],
        );
      },
    );
  }

  Widget _buildResults() {
    if (_searching) {
      return const BrandedStateView(
        icon: Icons.search_rounded,
        title: 'Searching',
        loading: true,
      );
    }
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
              if (_hits.isEmpty)
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
              else ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 2),
                  child: Text(
                    _hits.length == 1 ? '1 match' : '${_hits.length} matches',
                    style: AppTheme.lato(
                      fontSize: 12,
                      color: context.c.textMuted,
                    ),
                  ),
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
          onTap: enabled ? () => context.go('/tafseer/${summary.id}') : null,
          child: GoldCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _SurahNumberBadge(number: summary.surahNumber),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.nameUrdu,
                              style: AppTheme.amiriUrdu(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                                height: 1.9,
                              ),
                            ),
                            Text(
                              summary.titleUrdu,
                              style: AppTheme.amiriUrdu(
                                fontSize: 14,
                                color: c.textSecondary,
                                height: 1.9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        enabled
                            // The short surahs near the end of the Quran have
                            // a single ruku, so the noun has to agree.
                            ? '${summary.rukuCount} '
                                  '${summary.rukuCount == 1 ? 'ruku' : 'rukus'}'
                                  ' · Urdu'
                            : 'Coming soon',
                        style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.accentGold),
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
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.accentGold.o(0.14),
        border: Border.all(color: c.accentGold.o(0.85), width: 1.2),
      ),
      child: Text(
        toUrduDigits(number),
        style: AppTheme.amiriUrdu(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c.accentGold,
          height: 1.2,
        ),
      ),
    );
  }
}
