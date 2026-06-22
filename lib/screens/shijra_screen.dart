import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/shajra_pdf_registry.dart';
import '../models/shajra_entry_model.dart';
import '../models/shajra_urdu_detail_model.dart';
import '../services/shajra_bundled_service.dart';
import '../services/shajra_service.dart';
import '../services/shajra_urdu_details_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/standard_shell_header.dart';

class ShijraScreen extends StatefulWidget {
  const ShijraScreen({super.key});

  @override
  State<ShijraScreen> createState() => _ShijraScreenState();
}

class _ShijraScreenState extends State<ShijraScreen> {
  final _service = ShajraService();
  final _pdfs = ShajraPdfRegistry();
  final _urduDetails = ShajraUrduDetailsService();

  List<ShajraEntryModel>? _urduEntries;
  bool _urduLoading = false;
  Object? _urduError;

  List<ShajraEntryModel>? _englishEntries;
  bool _englishLoading = false;
  Object? _englishError;

  bool _englishSelected = true;

  @override
  void initState() {
    super.initState();
    _loadEnglish();
    _loadUrdu();
  }

  Future<void> _loadEnglish() async {
    setState(() {
      _englishLoading = true;
      _englishError = null;
    });
    try {
      final list = await _service.fetchEnglishShajraList();
      if (!mounted) return;
      setState(() {
        _englishEntries = list;
        _englishLoading = false;
        if (list.isEmpty) {
          _englishError = StateError('empty');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _englishError = e;
        _englishLoading = false;
      });
    }
  }

  Future<void> _loadUrdu() async {
    setState(() {
      _urduLoading = true;
      _urduError = null;
    });
    try {
      final list = await _service.fetchUrduShajraList();
      if (!mounted) return;
      setState(() {
        _urduEntries = list;
        _urduLoading = false;
        if (list.isEmpty) {
          _urduError = StateError('empty');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _urduError = e;
        _urduLoading = false;
      });
    }
  }

  void _openDetail(ShajraEntryModel entry, List<ShajraEntryModel> all) {
    final asset = _pdfs.assetFor(entry);
    if (asset != null && asset.isNotEmpty) {
      context.push(
        '/shajra/pdf',
        extra: ShajraPdfRouteArgs(entry: entry, assetPath: asset),
      );
      return;
    }
    context.push('/shajra/detail', extra: ShajraDetailRouteArgs(entry: entry, allEntries: all));
  }

  void _openUrduPdf(
    ShajraEntryModel entry,
    ShajraUrduDetailModel? detail,
    List<ShajraEntryModel> all,
  ) {
    if (detail != null && detail.storagePath.isNotEmpty) {
      context.push(
        '/shajra/urdu-pdf',
        extra: ShajraUrduPdfArgs(
          number: detail.number,
          titleUrdu: detail.titleUrdu.isNotEmpty ? detail.titleUrdu : entry.fullTitle,
          storagePath: detail.storagePath,
        ),
      );
      return;
    }
    if (ShajraBundledService.hasBundledUrduDetail(entry.number)) {
      context.push(
        '/shajra/detail',
        extra: ShajraDetailRouteArgs(entry: entry, allEntries: all),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBorder = isLight ? c.borderFaint : c.borderDefault;

    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StandardShellHeader(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shajra Pak',
                    style: AppTheme.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'شجرہ پاک',
                      style: AppTheme.amiriUrdu(
                        fontSize: 16,
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LanguageToggle(
                      c: c,
                      englishSelected: _englishSelected,
                      onEnglish: () => setState(() => _englishSelected = true),
                      onUrdu: () => setState(() => _englishSelected = false),
                    ),
                    const SizedBox(height: 14),
                    _IntroBanner(c: c),
                    const SizedBox(height: 18),
                    if (_englishSelected)
                      _EnglishBody(
                        c: c,
                        cardBorder: cardBorder,
                        loading: _englishLoading,
                        error: _englishError,
                        entries: _englishEntries,
                        onRetry: _loadEnglish,
                        onOpen: _openDetail,
                      )
                    else
                      _UrduBody(
                        c: c,
                        cardBorder: cardBorder,
                        loading: _urduLoading,
                        error: _urduError,
                        entries: _urduEntries,
                        onRetry: _loadUrdu,
                        detailsStream: _urduDetails.streamIndexByNumber(),
                        onOpen: _openUrduPdf,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.c,
    required this.englishSelected,
    required this.onEnglish,
    required this.onUrdu,
  });

  final AppThemeColors c;
  final bool englishSelected;
  final VoidCallback onEnglish;
  final VoidCallback onUrdu;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LangPill(
            c: c,
            selected: englishSelected,
            title: 'English',
            subtitle: 'Shajra Pak',
            onTap: onEnglish,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _LangPill(
            c: c,
            selected: !englishSelected,
            title: 'Urdu',
            subtitle: 'شجرہ پاک',
            onTap: onUrdu,
            urduSubtitle: true,
          ),
        ),
      ],
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.c,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.urduSubtitle = false,
  });

  final AppThemeColors c;
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool urduSubtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? c.accentGold : c.backgroundSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: c.accentGold,
              width: selected ? 0 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTheme.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? c.textPrimary : c.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: urduSubtitle
                    ? AppTheme.amiriUrdu(
                        fontSize: 15,
                        height: 1.3,
                        color: selected ? c.textPrimary : c.textMuted,
                      )
                    : AppTheme.cormorantGaramond(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected ? c.textPrimary : c.textMuted,
                        letterSpacing: 0.3,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({required this.c});

  final AppThemeColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: c.accentGold, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'اَللّٰھُمَّ صَلِّ عَلٰی سَیِّدِنَا مُحَمَّدٍ',
              textAlign: TextAlign.center,
              style: AppTheme.amiriUrdu(
                fontSize: 17,
                height: 1.9,
                color: c.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Silsila-e-Naqshbandia Mujadadia',
            textAlign: TextAlign.center,
            style: AppTheme.lato(
              fontSize: 11,
              color: c.textMuted,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _EnglishBody extends StatelessWidget {
  const _EnglishBody({
    required this.c,
    required this.cardBorder,
    required this.loading,
    required this.error,
    required this.entries,
    required this.onRetry,
    required this.onOpen,
  });

  final AppThemeColors c;
  final Color cardBorder;
  final bool loading;
  final Object? error;
  final List<ShajraEntryModel>? entries;
  final VoidCallback onRetry;
  final void Function(ShajraEntryModel, List<ShajraEntryModel>) onOpen;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _ShajraListShimmer(c: c);
    }
    if (error != null || entries == null || entries!.isEmpty) {
      return _ShajraErrorCard(c: c, onRetry: onRetry);
    }
    return _ShajraEntryList(
      c: c,
      cardBorder: cardBorder,
      entries: entries!,
      rtl: false,
      showChevron: true,
      tappable: true,
      onOpenTap: onOpen,
    );
  }
}

class _UrduBody extends StatelessWidget {
  const _UrduBody({
    required this.c,
    required this.cardBorder,
    required this.loading,
    required this.error,
    required this.entries,
    required this.onRetry,
    required this.detailsStream,
    required this.onOpen,
  });

  final AppThemeColors c;
  final Color cardBorder;
  final bool loading;
  final Object? error;
  final List<ShajraEntryModel>? entries;
  final VoidCallback onRetry;
  final Stream<Map<int, ShajraUrduDetailModel>> detailsStream;
  final void Function(ShajraEntryModel, ShajraUrduDetailModel?, List<ShajraEntryModel>) onOpen;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: _ShajraListShimmer(c: c),
      );
    }
    if (error != null || entries == null || entries!.isEmpty) {
      return _ShajraErrorCard(c: c, onRetry: onRetry);
    }
    return StreamBuilder<Map<int, ShajraUrduDetailModel>>(
      stream: detailsStream,
      builder: (context, snap) {
        final map = snap.data ?? const <int, ShajraUrduDetailModel>{};
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _UrduEntryList(
            c: c,
            cardBorder: cardBorder,
            entries: entries!,
            detailsByNumber: map,
            onOpen: onOpen,
          ),
        );
      },
    );
  }
}

class _UrduEntryList extends StatelessWidget {
  const _UrduEntryList({
    required this.c,
    required this.cardBorder,
    required this.entries,
    required this.detailsByNumber,
    required this.onOpen,
  });

  final AppThemeColors c;
  final Color cardBorder;
  final List<ShajraEntryModel> entries;
  final Map<int, ShajraUrduDetailModel> detailsByNumber;
  final void Function(ShajraEntryModel, ShajraUrduDetailModel?, List<ShajraEntryModel>) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(entries.length, (i) {
        final e = entries[i];
        final d = detailsByNumber[e.number];
        final pdfAvailable = d != null && d.storagePath.isNotEmpty;
        final bioAvailable = ShajraBundledService.hasBundledUrduDetail(e.number);
        final canOpen = pdfAvailable || bioAvailable;
        final isFirst = e.number == 1;
        final isLast = i == entries.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 46,
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    _NumberCircle(
                      c: c,
                      number: e.number,
                      filled: isFirst,
                      outlined: !isFirst,
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: _TimelineDotsPainter(
                          color: c.accentGold,
                          active: !isLast,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canOpen ? () => onOpen(e, d, entries) : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: _cardDecoration(c, cardBorder, isFirst),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.listDisplayName,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.amiriUrdu(
                                  fontSize: 16,
                                  height: 1.35,
                                  color: canOpen ? c.textPrimary : c.textFaint,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (pdfAvailable)
                              Icon(Icons.picture_as_pdf_outlined, color: c.accentGold, size: 18)
                            else if (bioAvailable)
                              Icon(Icons.menu_book_outlined, color: c.accentGold, size: 18)
                            else
                              Text(
                                'Not added',
                                style: AppTheme.lato(
                                  fontSize: 11,
                                  color: c.textFaint,
                                ),
                              ),
                            const SizedBox(width: 6),
                            CustomPaint(
                              size: const Size(10, 16),
                              painter: _ChevronPainter(
                                canOpen ? c.accentGold : c.textFaint,
                                pointRight: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ShajraListShimmer extends StatelessWidget {
  const _ShajraListShimmer({required this.c});

  final AppThemeColors c;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(10, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ShimmerPlaceholder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: const SizedBox(
                        height: 14,
                        width: double.infinity,
                        child: ShimmerPlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 12,
                        width: MediaQuery.sizeOf(context).width * 0.55,
                        child: const ShimmerPlaceholder(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ShajraErrorCard extends StatelessWidget {
  const _ShajraErrorCard({required this.c, required this.onRetry});

  final AppThemeColors c;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: c.backgroundSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.borderDefault.o(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(52, 52),
              painter: _WifiOffPainter(c.accentGold),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load Shajra',
              textAlign: TextAlign.center,
              style: AppTheme.cormorantGaramond(
                fontSize: 18,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection',
              textAlign: TextAlign.center,
              style: AppTheme.lato(fontSize: 13, color: c.textMuted),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accentGold,
                side: BorderSide(color: c.accentGold, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: Text(
                'Try Again',
                style: AppTheme.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.accentGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShajraEntryList extends StatelessWidget {
  const _ShajraEntryList({
    required this.c,
    required this.cardBorder,
    required this.entries,
    required this.rtl,
    required this.showChevron,
    required this.tappable,
    this.onOpenTap,
  });

  final AppThemeColors c;
  final Color cardBorder;
  final List<ShajraEntryModel> entries;
  final bool rtl;
  final bool showChevron;
  final bool tappable;
  final void Function(ShajraEntryModel, List<ShajraEntryModel>)? onOpenTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(entries.length, (i) {
        final e = entries[i];
        final isFirst = e.number == 1;
        final isLast = i == entries.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 46,
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    _NumberCircle(
                      c: c,
                      number: e.number,
                      filled: isFirst,
                      outlined: !isFirst,
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: _TimelineDotsPainter(
                          color: c.accentGold,
                          active: !isLast,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: Material(
                    color: Colors.transparent,
                    child: tappable && onOpenTap != null
                        ? InkWell(
                            onTap: () => onOpenTap!(e, entries),
                            borderRadius: BorderRadius.circular(12),
                            child: Ink(
                              decoration: _cardDecoration(c, cardBorder, isFirst),
                              padding: const EdgeInsets.all(14),
                              child: _ShajraCardContent(
                                c: c,
                                e: e,
                                rtl: rtl,
                                isFirst: isFirst,
                                showChevron: showChevron,
                              ),
                            ),
                          )
                        : Ink(
                            decoration: _cardDecoration(c, cardBorder, isFirst),
                            padding: const EdgeInsets.all(14),
                            child: _ShajraCardContent(
                              c: c,
                              e: e,
                              rtl: rtl,
                              isFirst: isFirst,
                              showChevron: showChevron,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

BoxDecoration _cardDecoration(AppThemeColors c, Color cardBorder, bool isFirst) {
  return BoxDecoration(
    color: isFirst ? c.accentGold.o(0.15) : c.backgroundSurface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isFirst ? c.accentGold : cardBorder,
      width: 1,
    ),
  );
}

class _ShajraCardContent extends StatelessWidget {
  const _ShajraCardContent({
    required this.c,
    required this.e,
    required this.rtl,
    required this.isFirst,
    required this.showChevron,
  });

  final AppThemeColors c;
  final ShajraEntryModel e;
  final bool rtl;
  final bool isFirst;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                e.listDisplayName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: isFirst
                    ? (rtl
                        ? AppTheme.amiriUrdu(
                            fontSize: 16,
                            height: 1.35,
                            color: c.accentGold,
                          )
                        : AppTheme.cormorantGaramond(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.accentGold,
                          ))
                    : rtl
                        ? AppTheme.amiriUrdu(
                            fontSize: 16,
                            height: 1.35,
                            color: c.textPrimary,
                          )
                        : AppTheme.cormorantGaramond(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
                          ),
              ),
            ],
          ),
        ),
        if (showChevron) ...[
          const SizedBox(width: 6),
          CustomPaint(
            size: const Size(10, 16),
            painter: _ChevronPainter(
              c.accentGold,
              pointRight: !rtl,
            ),
          ),
        ],
      ],
    );
  }
}

class _NumberCircle extends StatelessWidget {
  const _NumberCircle({
    required this.c,
    required this.number,
    required this.filled,
    required this.outlined,
  });

  final AppThemeColors c;
  final int number;
  final bool filled;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? c.accentGold : Colors.transparent,
        border: outlined ? Border.all(color: c.accentGold, width: 2) : null,
      ),
      child: Text(
        '$number',
        style: AppTheme.cormorantGaramond(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: filled ? c.textPrimary : c.textPrimary,
        ),
      ),
    );
  }
}

class _TimelineDotsPainter extends CustomPainter {
  _TimelineDotsPainter({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final p = Paint()
      ..color = color.o(0.85)
      ..style = PaintingStyle.fill;

    const dotR = 1.6;
    const gap = 7.0;
    final x = size.width / 2;
    double y = 4;
    while (y < size.height - 4) {
      canvas.drawCircle(Offset(x, y), dotR, p);
      y += gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineDotsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.active != active;
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color, {required this.pointRight});

  final Color color;
  final bool pointRight;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.35;
    if (pointRight) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - w * 0.3, cy - w * 0.55)
          ..lineTo(cx + w * 0.45, cy)
          ..lineTo(cx - w * 0.3, cy + w * 0.55),
        p,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(cx + w * 0.3, cy - w * 0.55)
          ..lineTo(cx - w * 0.45, cy)
          ..lineTo(cx + w * 0.3, cy + w * 0.55),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointRight != pointRight;
}

class _WifiOffPainter extends CustomPainter {
  _WifiOffPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final c = Offset(size.width / 2, size.height * 0.55);
    final w = size.width * 0.42;
    canvas.drawArc(Rect.fromCenter(center: c, width: w, height: w * 0.55), 3.5, 2.2, false, p);
    canvas.drawArc(Rect.fromCenter(center: c, width: w * 1.45, height: w * 0.9), 3.45, 2.3, false, p);
    canvas.drawArc(Rect.fromCenter(center: c, width: w * 2.1, height: w * 1.25), 3.4, 2.35, false, p);

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.82, size.height * 0.82),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _WifiOffPainter oldDelegate) => oldDelegate.color != color;
}
