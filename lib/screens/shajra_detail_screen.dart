import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../navigation/go_router_helpers.dart';
import '../data/shajra_pdf_registry.dart';
import '../models/shajra_entry_model.dart';
import '../services/shajra_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/ornament_divider.dart';
import '../widgets/shimmer_placeholder.dart';

class ShajraDetailScreen extends StatefulWidget {
  const ShajraDetailScreen({super.key, required this.args});

  final ShajraDetailRouteArgs args;

  @override
  State<ShajraDetailScreen> createState() => _ShajraDetailScreenState();
}

class _ShajraDetailScreenState extends State<ShajraDetailScreen> {
  final _service = ShajraService();
  final _pdfs = ShajraPdfRegistry();
  late List<ShajraEntryModel> _entries;
  late int _index;
  String? _html;
  bool _loading = true;
  Object? _error;

  ShajraEntryModel get _entry => _entries[_index];

  @override
  void initState() {
    super.initState();
    _entries = List<ShajraEntryModel>.from(widget.args.allEntries);
    _index = _entries.indexWhere((e) => e.number == widget.args.entry.number);
    if (_index < 0) _index = 0;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _html = null;
    });

    final e = _entry;
    if (e.language == ShajraEntryModel.urdu || e.detailUrl.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _loading = false;
        _html = _urduPlaceholderHtml(e.fullTitle);
      });
      return;
    }

    try {
      final html = await _service.fetchEntryDetail(e.detailUrl);
      if (!mounted) return;
      setState(() {
        _html = html;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err;
        _loading = false;
      });
    }
  }

  String _urduPlaceholderHtml(String title) {
    const body =
        '<p>اردو متن جلد یہاں شامل کیا جائے گا۔</p><p>اللّٰمہ کاتبؔ کے مضامین اور سلسلہ کے حوالے سے مزید معلومات کے لیے براہ کرم بعد میں دوبارہ چیک کریں۔</p>';
    return '<h2>${_escapeXml(title)}</h2>$body';
  }

  String _escapeXml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  void _goRelative(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= _entries.length) return;
    setState(() => _index = next);
    _load();
  }

  Future<void> _share() async {
    final name = _entry.shortName.isNotEmpty ? _entry.shortName : _entry.fullTitle;
    await Share.share(
      'Shajra Pak — $name\nAl Nisar App',
    );
  }

  void _openPdfIfAvailable() {
    final asset = _pdfs.assetFor(_entry);
    if (asset == null || asset.isEmpty) return;
    context.push('/shajra/pdf', extra: ShajraPdfRouteArgs(entry: _entry, assetPath: asset));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canPrev = _index > 0;
    final canNext = _index < _entries.length - 1;
    final pdfAsset = _pdfs.assetFor(_entry);

    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailHeader(
              entry: _entry,
              onBack: () => popOrGoHome(context),
            ),
            Expanded(
              child: Stack(
                children: [
                  _loading
                      ? _DetailShimmer(c: c)
                      : _error != null
                          ? _DetailError(
                              c: c,
                              onRetry: _load,
                            )
                          : _DetailScroll(
                              c: c,
                              entry: _entry,
                              html: _html ?? '',
                            ),
                  // Positioned(
                  //   right: 16,
                  //   bottom: 88,
                  //   child: Material(
                  //     color: Colors.transparent,
                  //     child: InkWell(
                  //       onTap: _share,
                  //       customBorder: const CircleBorder(),
                  //       child: Ink(
                  //         width: 52,
                  //         height: 52,
                  //         decoration: BoxDecoration(
                  //           shape: BoxShape.circle,
                  //           color: c.accentGold.o(0.22),
                  //           border: Border.all(color: c.accentGold, width: 1.2),
                  //         ),
                  //         child: Center(
                  //           child: CustomPaint(
                  //             size: const Size(22, 22),
                  //             painter: _ShareIconPainter(c.accentGold),
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  if (pdfAsset != null && pdfAsset.isNotEmpty)
                    Positioned(
                      right: 16,
                      bottom: 24,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openPdfIfAvailable,
                          customBorder: const CircleBorder(),
                          child: Ink(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.accentGold.o(0.22),
                              border: Border.all(color: c.accentGold, width: 1.2),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.picture_as_pdf_outlined,
                                color: c.accentGold,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _OutlineNavButton(
                      label: '← Previous',
                      enabled: canPrev,
                      onTap: canPrev ? () => _goRelative(-1) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OutlineNavButton(
                      label: 'Next →',
                      enabled: canNext,
                      onTap: canNext ? () => _goRelative(1) : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.entry, required this.onBack});

  final ShajraEntryModel entry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.accentGold, size: 20),
          ),
          IconButton(
            onPressed: () => goAppHome(context),
            icon: Icon(Icons.home_outlined, color: c.accentGold, size: 22),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.accentGold.o(0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.accentGold.o(0.85)),
            ),
            child: Text(
              'No. ${entry.number}',
              style: AppTheme.lato(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.shortName.isNotEmpty ? entry.shortName : entry.fullTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.cormorantGaramond(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer({required this.c});

  final AppThemeColors c;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const SizedBox(
                height: 72,
                child: ShimmerPlaceholder(),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.c, required this.onRetry});

  final AppThemeColors c;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(56, 56),
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

class _DetailScroll extends StatelessWidget {
  const _DetailScroll({
    required this.c,
    required this.entry,
    required this.html,
  });

  final AppThemeColors c;
  final ShajraEntryModel entry;
  final String html;

  @override
  Widget build(BuildContext context) {
    final latoFamily = GoogleFonts.lato().fontFamily;
    final cgFamily = GoogleFonts.cormorantGaramond().fontFamily;
    final bodyHtml = _stripLeadingH2(html);

    final htmlStyle = <String, Style>{
      'body': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        backgroundColor: Colors.transparent,
        fontFamily: latoFamily,
        fontSize: FontSize(15),
        color: c.textSecondary,
        lineHeight: const LineHeight(1.8),
      ),
      'p': Style(
        margin: Margins.only(bottom: 12),
        lineHeight: const LineHeight(1.8),
        fontFamily: latoFamily,
        fontSize: FontSize(15),
        color: c.textSecondary,
      ),
      'h1': Style(
        fontFamily: cgFamily,
        fontSize: FontSize(20),
        color: c.accentGold,
        margin: Margins.only(bottom: 10, top: 8),
      ),
      'h2': Style(
        fontFamily: cgFamily,
        fontSize: FontSize(19),
        color: c.accentGold,
        margin: Margins.only(bottom: 10, top: 8),
      ),
      'h3': Style(
        fontFamily: cgFamily,
        fontSize: FontSize(18),
        color: c.accentGold,
        margin: Margins.only(bottom: 8, top: 6),
      ),
      'img': Style(display: Display.none),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: c.accentGold.o(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: c.accentGold, width: 4),
              ),
            ),
            child: Text(
              entry.fullTitle,
              style: AppTheme.cormorantGaramond(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const OrnamentDivider(),
          const SizedBox(height: 16),
          Html(
            data: bodyHtml.isNotEmpty ? bodyHtml : html,
            shrinkWrap: true,
            style: htmlStyle,
            onLinkTap: (url, attributes, element) {},
          ),
        ],
      ),
    );
  }

  /// Avoid duplicating the honorific block already shown in the top card.
  static String _stripLeadingH2(String raw) {
    return raw.replaceFirst(
      RegExp(r'<h2[^>]*>[\s\S]*?</h2>', caseSensitive: false),
      '',
    ).trim();
  }
}

class _OutlineNavButton extends StatelessWidget {
  const _OutlineNavButton({
    required this.label,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = enabled ? c.accentGold : c.textFaint;
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        disabledForegroundColor: c.textFaint,
        side: BorderSide(color: enabled ? c.accentGold : c.borderDefault.o(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: AppTheme.lato(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: enabled ? c.textPrimary : c.textFaint,
        ),
      ),
    );
  }
}

class _ShareIconPainter extends CustomPainter {
  _ShareIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width * 0.35;
    final cy = size.height * 0.42;
    final r = size.width * 0.12;
    canvas.drawCircle(Offset(cx, cy), r, p);

    final path = Path()
      ..moveTo(size.width * 0.55, size.height * 0.32)
      ..lineTo(size.width * 0.82, size.height * 0.22)
      ..moveTo(size.width * 0.55, size.height * 0.52)
      ..lineTo(size.width * 0.82, size.height * 0.62);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _ShareIconPainter oldDelegate) =>
      oldDelegate.color != color;
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
  bool shouldRepaint(covariant _WifiOffPainter oldDelegate) =>
      oldDelegate.color != color;
}
