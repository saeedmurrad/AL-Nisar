import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/tafseer_models.dart';
import '../services/tafseer_bundled_service.dart';
import '../theme/app_layout.dart';
import '../theme/app_theme_colors.dart';
import '../theme/tafseer_theme.dart';
import '../utils/responsive_layout.dart';
import '../utils/urdu_digits.dart';
import '../widgets/app_drawer.dart';
import '../widgets/branded_state_view.dart';
import '../widgets/islamic_ui.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/tafseer_html.dart';

/// A surah's front matter: masthead, preface, symbol key and ruku index.
class TafseerSurahScreen extends StatefulWidget {
  const TafseerSurahScreen({super.key, required this.surahId, this.service});

  final String surahId;

  /// Injectable for tests; defaults to the bundled assets.
  final TafseerBundledService? service;

  @override
  State<TafseerSurahScreen> createState() => _TafseerSurahScreenState();
}

class _TafseerSurahScreenState extends State<TafseerSurahScreen> {
  late final _service = widget.service ?? TafseerBundledService();
  late Future<TafseerSurah?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadSurah(widget.surahId);
  }

  @override
  void didUpdateWidget(covariant TafseerSurahScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahId != widget.surahId) {
      _future = _service.loadSurah(widget.surahId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TafseerSurah?>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final surah = snap.data;

        // The reading area uses the tafseer paper palette; the shell header
        // stays on the app's emerald chrome.
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
                    StandardShellHeader(
                      title: surah?.nameUrdu ?? 'Tafseer',
                      onBack: () => context.go('/tafseer'),
                    ),
                    Expanded(
                      child: loading
                          ? const BrandedStateView(
                              icon: Icons.auto_stories_outlined,
                              title: 'Loading tafseer',
                              loading: true,
                            )
                          : surah == null
                          ? BrandedStateView(
                              icon: Icons.search_off_rounded,
                              title: 'Tafseer not found',
                              message:
                                  'No commentary is bundled for "${widget.surahId}".',
                              action: OutlinedButton(
                                onPressed: () => context.go('/tafseer'),
                                child: const Text('Back to Tafseer'),
                              ),
                            )
                          : _SurahBody(surah: surah),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SurahBody extends StatelessWidget {
  const _SurahBody({required this.surah});

  final TafseerSurah surah;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          ContentColumn(
            maxWidth: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Masthead(surah: surah),
                const SizedBox(height: AppLayout.lg),
                _Preface(surah: surah),
                const SizedBox(height: 28),
                _RukuIndex(surah: surah),
                const SizedBox(height: 32),
                _Colophon(html: surah.colophonHtml),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.surah});

  final TafseerSurah surah;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderDefault)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            surah.basmala,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: tafseerArabicFamily,
              fontSize: 26,
              height: 1.8,
              color: c.accentGold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            surah.titleUrdu,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: tafseerUrduFamily,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.9,
              color: TafseerPalette.lapis(context),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            surah.subtitleUrdu,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: tafseerUrduFamily,
              fontSize: 15,
              height: 2.2,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            surah.kicker,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: tafseerUrduFamily,
              fontSize: 12.5,
              letterSpacing: 0.8,
              height: 2,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Preface extends StatelessWidget {
  const _Preface({required this.surah});

  final TafseerSurah surah;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      decoration: BoxDecoration(
        color: c.backgroundSurface,
        // border-inline-start under RTL is the right edge.
        border: Border(right: BorderSide(color: c.accentGold, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TafseerHtml(data: surah.prefaceHtml.join(), fontSize: 15),
          if (surah.key.isNotEmpty) _KeyList(entries: surah.key),
        ],
      ),
    );
  }
}

class _KeyList extends StatelessWidget {
  const _KeyList({required this.entries});

  final List<TafseerKeyEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final twoUp = ResponsiveLayout.screenWidth(context) >= 560;
    final lapis = TafseerPalette.lapis(context);

    final rows = [
      for (final e in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${e.term} ',
                  style: TextStyle(
                    fontFamily: tafseerUrduFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 2.1,
                    color: lapis,
                  ),
                ),
                TextSpan(
                  text: e.meaning,
                  style: TextStyle(
                    fontFamily: tafseerUrduFamily,
                    fontSize: 14,
                    height: 2.1,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
    ];

    if (!twoUp) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    }

    final mid = (rows.length + 1) ~/ 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows.sublist(0, mid),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows.sublist(mid),
          ),
        ),
      ],
    );
  }
}

class _RukuIndex extends StatelessWidget {
  const _RukuIndex({required this.surah});

  final TafseerSurah surah;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderDefault),
          bottom: BorderSide(color: c.borderDefault),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'فہرستِ رکوع',
              style: TextStyle(
                fontFamily: tafseerUrduFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 2,
                color: c.textMuted,
              ),
            ),
          ),
          for (final r in surah.rukus)
            _RukuIndexRow(surahId: surah.id, ruku: r),
        ],
      ),
    );
  }
}

class _RukuIndexRow extends StatelessWidget {
  const _RukuIndexRow({required this.surahId, required this.ruku});

  final String surahId;
  final TafseerRuku ruku;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/tafseer/$surahId/${ruku.number}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  toUrduDigits(ruku.number),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: tafseerArabicFamily,
                    fontSize: 16,
                    color: c.accentGold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ruku.titleUrdu,
                  style: TextStyle(
                    fontFamily: tafseerUrduFamily,
                    fontSize: 15,
                    height: 2.1,
                    color: c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                ruku.ayahRangeUrdu,
                style: TextStyle(
                  fontFamily: tafseerArabicFamily,
                  fontSize: 13,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Colophon extends StatelessWidget {
  const _Colophon({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (html.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderDefault)),
      ),
      child: Text(
        html.replaceAll(RegExp(r'<br\s*/?>'), '\n').replaceAll(
          RegExp(r'<[^>]+>'),
          '',
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: tafseerUrduFamily,
          fontSize: 13,
          height: 2.2,
          color: c.textMuted,
        ),
      ),
    );
  }
}
