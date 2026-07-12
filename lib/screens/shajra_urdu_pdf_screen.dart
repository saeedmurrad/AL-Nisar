import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../navigation/go_router_helpers.dart';
import '../models/shajra_entry_model.dart';
import '../services/book_service.dart';
import '../services/pdf_cache_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/pdf_nav_controls.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ShajraUrduPdfScreen extends StatefulWidget {
  const ShajraUrduPdfScreen({super.key, required this.args});

  final ShajraUrduPdfArgs args;

  @override
  State<ShajraUrduPdfScreen> createState() => _ShajraUrduPdfScreenState();
}

class _ShajraUrduPdfScreenState extends State<ShajraUrduPdfScreen> {
  final _books = BookService(); // only used to get Storage download URL
  final _cache = PdfCacheService();
  final _pdf = PdfViewerController();

  Uint8List? _pdfBytes;
  bool _loading = true;
  bool _failed = false;
  double? _progress;

  String get _cacheId => 'shajra_urdu_${widget.args.number}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
      _progress = null;
      _pdfBytes = null;
    });

    final cached = await _cache.getCachedPdfBytes(_cacheId);
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _pdfBytes = cached;
        _loading = false;
      });
      return;
    }

    try {
      setState(() => _progress = 0);
      final url = await _books.getBookDownloadUrl(widget.args.storagePath);
      final f = await _cache.downloadAndCachePdf(_cacheId, url, (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (!mounted) return;
      setState(() {
        _pdfBytes = f;
        _loading = false;
        _failed = false;
        _progress = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _progress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
              decoration: BoxDecoration(
                color: c.backgroundSurface,
                border: Border(
                  bottom: BorderSide(color: c.borderDefault.o(0.55)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => popOrGoHome(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: c.accentGold,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => goAppHome(context),
                    icon: Icon(
                      Icons.home_outlined,
                      color: c.accentGold,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        widget.args.titleUrdu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.amiriUrdu(
                          fontSize: 16,
                          height: 1.4,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: _progress == null
                          ? CircularProgressIndicator(color: c.accentGold)
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Downloading PDF…',
                                    style: AppTheme.lato(color: c.textMuted),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: _progress,
                                      minHeight: 7,
                                      backgroundColor: c.backgroundElevated,
                                      color: c.accentGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    )
                  : _failed || _pdfBytes == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Could not load PDF',
                              style: AppTheme.cormorantGaramond(
                                fontSize: 18,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: _load,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: c.accentGold,
                                side: BorderSide(color: c.accentGold),
                              ),
                              child: Text('Try Again', style: AppTheme.lato()),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: SfPdfViewerTheme(
                            data: SfPdfViewerThemeData(
                              backgroundColor: c.backgroundPrimary,
                              progressBarColor: c.accentGold,
                            ),
                            // Urdu shajra reads right-to-left.
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: SfPdfViewer.memory(
                                _pdfBytes!,
                                controller: _pdf,
                                scrollDirection: PdfScrollDirection.horizontal,
                                pageLayoutMode: PdfPageLayoutMode.single,
                                enableTextSelection: true,
                                canShowScrollHead: true,
                                canShowScrollStatus: true,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: PdfNavControls(controller: _pdf, rtl: true),
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
