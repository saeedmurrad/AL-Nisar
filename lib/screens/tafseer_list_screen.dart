import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/tafseer_models.dart';
import '../services/tafseer_bundled_service.dart';
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

/// Tafseer index: the surahs with bundled commentary.
class TafseerListScreen extends StatefulWidget {
  const TafseerListScreen({super.key, this.service});

  /// Injectable for tests; defaults to the bundled assets.
  final TafseerBundledService? service;

  @override
  State<TafseerListScreen> createState() => _TafseerListScreenState();
}

class _TafseerListScreenState extends State<TafseerListScreen> {
  late final _service = widget.service ?? TafseerBundledService();
  late Future<List<TafseerSurahSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadIndex();
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
          Expanded(
            child: FutureBuilder<List<TafseerSurahSummary>>(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppLayout.md,
                        ),
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
            ),
          ),
        ],
      ),
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
                            ? '${summary.rukuCount} rukus · Urdu'
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
