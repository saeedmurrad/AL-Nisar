import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';

import '../models/tafseer_models.dart';
import '../services/tafseer_bundled_service.dart';
import '../theme/app_layout.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../theme/tafseer_theme.dart';
import '../utils/responsive_layout.dart';
import '../widgets/app_drawer.dart';
import '../widgets/branded_state_view.dart';
import '../widgets/islamic_ui.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/tafseer_html.dart';

/// One ruku of tafseer: marker, title, ayah block, prose body and لغات panel.
class TafseerRukuScreen extends StatefulWidget {
  const TafseerRukuScreen({
    super.key,
    required this.surahId,
    required this.rukuNumber,
    this.service,
  });

  final String surahId;
  final int rukuNumber;

  /// Injectable for tests; defaults to the bundled assets.
  final TafseerBundledService? service;

  @override
  State<TafseerRukuScreen> createState() => _TafseerRukuScreenState();
}

class _TafseerRukuScreenState extends State<TafseerRukuScreen> {
  late final _service = widget.service ?? TafseerBundledService();
  final _scroll = ScrollController();

  TafseerSurah? _surah;
  String? _bodyHtml;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TafseerRukuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahId != widget.surahId ||
        oldWidget.rukuNumber != widget.rukuNumber) {
      _load();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _bodyHtml = null;
    });
    final surah = await _service.loadSurah(widget.surahId);
    final html = await _service.loadRukuHtml(widget.surahId, widget.rukuNumber);
    if (!mounted) return;
    setState(() {
      _surah = surah;
      _bodyHtml = html;
      _loading = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _goRelative(int delta) {
    final next = widget.rukuNumber + delta;
    final surah = _surah;
    if (surah == null || surah.rukuByNumber(next) == null) return;
    context.go('/tafseer/${widget.surahId}/$next');
  }

  @override
  Widget build(BuildContext context) {
    final surah = _surah;
    final ruku = surah?.rukuByNumber(widget.rukuNumber);
    final canPrev = surah?.rukuByNumber(widget.rukuNumber - 1) != null;
    final canNext = surah?.rukuByNumber(widget.rukuNumber + 1) != null;

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
                  onBack: () => context.go('/tafseer/${widget.surahId}'),
                ),
                Expanded(
                  child: _loading
                      ? const BrandedStateView(
                          icon: Icons.auto_stories_outlined,
                          title: 'Loading ruku',
                          loading: true,
                        )
                      : (ruku == null || _bodyHtml == null)
                      ? BrandedStateView(
                          icon: Icons.search_off_rounded,
                          title: 'Ruku not found',
                          message:
                              'Ruku ${widget.rukuNumber} is not part of this tafseer.',
                          action: OutlinedButton(
                            onPressed: () =>
                                context.go('/tafseer/${widget.surahId}'),
                            child: const Text('Back to contents'),
                          ),
                        )
                      : _RukuBody(
                          controller: _scroll,
                          ruku: ruku,
                          bodyHtml: _bodyHtml!,
                        ),
                ),
                if (!_loading && ruku != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: ContentColumn(
                      maxWidth: 700,
                      child: Row(
                        children: [
                          Expanded(
                            child: _OutlineNavButton(
                              label: '← پچھلا رکوع',
                              enabled: canPrev,
                              onTap: () => _goRelative(-1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _OutlineNavButton(
                              label: 'اگلا رکوع →',
                              enabled: canNext,
                              onTap: () => _goRelative(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RukuBody extends StatelessWidget {
  const _RukuBody({
    required this.controller,
    required this.ruku,
    required this.bodyHtml,
  });

  final ScrollController controller;
  final TafseerRuku ruku;
  final String bodyHtml;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          ContentColumn(
            maxWidth: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RukuMarker(ruku: ruku),
                const SizedBox(height: 8),
                Text(
                  ruku.titleUrdu,
                  style: TextStyle(
                    fontFamily: tafseerUrduFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 2,
                    color: TafseerPalette.lapis(context),
                  ),
                ),
                const SizedBox(height: 18),
                if (ruku.ayahBlock.isNotEmpty) ...[
                  Text(
                    ruku.ayahBlock,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: tafseerArabicFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 2,
                      color: c.accentGold,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                TafseerHtml(data: bodyHtml),
                if (ruku.glossary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _GlossaryPanel(entries: ruku.glossary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The circled ع, the ruku eyebrow, and a rule filling the rest of the line.
class _RukuMarker extends StatelessWidget {
  const _RukuMarker({required this.ruku});

  final TafseerRuku ruku;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.accentGold, width: 1.5),
          ),
          child: Text(
            'ع',
            style: TextStyle(
              fontFamily: tafseerArabicFamily,
              fontSize: 19,
              height: 1.1,
              color: c.accentGold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            ruku.eyebrow,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: tafseerUrduFamily,
              fontSize: 13,
              height: 2,
              color: c.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Container(height: 1, color: c.borderDefault)),
      ],
    );
  }
}

/// مشکل الفاظ اور اصطلاحاتِ فقر — the artifact's glossary aside.
class _GlossaryPanel extends StatelessWidget {
  const _GlossaryPanel({required this.entries});

  final List<TafseerGlossaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Below 540px the artifact stacks each term above its definition.
    final sideBySide = ResponsiveLayout.screenWidth(context) >= 540;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: c.backgroundElevated,
        border: Border(top: BorderSide(color: c.accentGold, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'مشکل الفاظ اور اصطلاحاتِ فقر',
            style: TextStyle(
              fontFamily: tafseerUrduFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 2,
              color: TafseerPalette.lapis(context),
            ),
          ),
          const SizedBox(height: 8),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: sideBySide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 170),
                          child: _GlossaryTerm(term: e.term),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _GlossaryDefinition(html: e.definitionHtml)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GlossaryTerm(term: e.term),
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: _GlossaryDefinition(html: e.definitionHtml),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class _GlossaryTerm extends StatelessWidget {
  const _GlossaryTerm({required this.term});

  final String term;

  @override
  Widget build(BuildContext context) {
    return Text(
      term,
      style: TextStyle(
        fontFamily: tafseerUrduFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 2.1,
        color: context.c.accentGold,
      ),
    );
  }
}

class _GlossaryDefinition extends StatelessWidget {
  const _GlossaryDefinition({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Html(
      data: '<p>$html</p>',
      shrinkWrap: true,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          backgroundColor: Colors.transparent,
        ),
        'p': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontFamily: tafseerUrduFamily,
          fontSize: FontSize(14),
          lineHeight: LineHeight(2.1),
          color: c.textSecondary,
          textAlign: TextAlign.right,
          direction: TextDirection.rtl,
        ),
        'b': Style(fontWeight: FontWeight.w600, color: c.accentGold),
      },
    );
  }
}

class _OutlineNavButton extends StatelessWidget {
  const _OutlineNavButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: c.accentGold,
        disabledForegroundColor: c.textFaint,
        side: BorderSide(
          color: enabled ? c.accentGold : c.borderDefault.o(0.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: tafseerUrduFamily,
          fontSize: 13,
          height: 1.9,
          color: enabled ? c.textPrimary : c.textFaint,
        ),
      ),
    );
  }
}
