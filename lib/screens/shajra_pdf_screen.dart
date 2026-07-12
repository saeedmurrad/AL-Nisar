import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../navigation/go_router_helpers.dart';
import '../models/shajra_entry_model.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/pdf_nav_controls.dart';

class ShajraPdfScreen extends StatefulWidget {
  const ShajraPdfScreen({super.key, required this.args});

  final ShajraPdfRouteArgs args;

  @override
  State<ShajraPdfScreen> createState() => _ShajraPdfScreenState();
}

class _ShajraPdfScreenState extends State<ShajraPdfScreen> {
  final _pdf = PdfViewerController();
  bool _missingAsset = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final title = widget.args.entry.shortName.isNotEmpty
        ? widget.args.entry.shortName
        : widget.args.entry.fullTitle;

    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: title, onBack: () => popOrGoHome(context)),
            Expanded(
              child: _missingAsset
                  ? _MissingPdf(title: title, assetPath: widget.args.assetPath)
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: SfPdfViewerTheme(
                            data: SfPdfViewerThemeData(
                              backgroundColor: c.backgroundPrimary,
                              progressBarColor: c.accentGold,
                            ),
                            child: SfPdfViewer.asset(
                              widget.args.assetPath,
                              controller: _pdf,
                              scrollDirection: PdfScrollDirection.horizontal,
                              pageLayoutMode: PdfPageLayoutMode.single,
                              onDocumentLoadFailed: (_) {
                                if (mounted) {
                                  setState(() => _missingAsset = true);
                                }
                              },
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: PdfNavControls(controller: _pdf, rtl: false),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
      decoration: BoxDecoration(
        color: c.backgroundSurface,
        border: Border(bottom: BorderSide(color: c.borderDefault.o(0.55))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: c.accentGold,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () => goAppHome(context),
            icon: Icon(Icons.home_outlined, color: c.accentGold, size: 22),
          ),
          Expanded(
            child: Text(
              title,
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

class _MissingPdf extends StatelessWidget {
  const _MissingPdf({required this.title, required this.assetPath});

  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_outlined, color: c.accentGold, size: 44),
            const SizedBox(height: 12),
            Text(
              'PDF not found',
              style: AppTheme.cormorantGaramond(
                fontSize: 20,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.lato(color: c.textMuted),
            ),
            const SizedBox(height: 10),
            Text(
              assetPath,
              textAlign: TextAlign.center,
              style: AppTheme.lato(fontSize: 11, color: c.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}
