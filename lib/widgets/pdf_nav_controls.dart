import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';

/// True when [s] contains Arabic-script (Urdu) characters, i.e. the document
/// should read right-to-left. Covers Arabic, Arabic Supplement/Extended-A,
/// and the Arabic Presentation Forms A/B blocks.
bool isRtlText(String s) => RegExp(
  r'[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]',
).hasMatch(s);

/// Left & right edge page-turn buttons overlaid on an [SfPdfViewer].
///
/// The chevrons always point outward (‹ on the left, › on the right); only
/// the *action* flips with [rtl]. So an Urdu (right-to-left) book turns pages
/// in its natural flow — the left chevron advances to the next page and the
/// right chevron goes back — while a left-to-right book does the opposite.
///
/// Place it as a `Positioned.fill` above the viewer; the empty middle stays
/// transparent to taps so the viewer keeps receiving gestures.
class PdfNavControls extends StatelessWidget {
  const PdfNavControls({
    super.key,
    required this.controller,
    this.rtl = false,
  });

  final PdfViewerController controller;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.pageNumber;
        final count = controller.pageCount;
        final canPrev = page > 1;
        final canNext = count > 0 && page < count;

        final leftEnabled = rtl ? canNext : canPrev;
        final rightEnabled = rtl ? canPrev : canNext;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _NavButton(
                  colors: c,
                  icon: Icons.chevron_left_rounded,
                  enabled: leftEnabled,
                  onTap: () =>
                      rtl ? controller.nextPage() : controller.previousPage(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _NavButton(
                  colors: c,
                  icon: Icons.chevron_right_rounded,
                  enabled: rightEnabled,
                  onTap: () =>
                      rtl ? controller.previousPage() : controller.nextPage(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.colors,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final AppThemeColors colors;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.28,
      child: Material(
        color: colors.backgroundSurface.o(0.85),
        shape: CircleBorder(
          side: BorderSide(color: colors.accentGold.o(0.6), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 30, color: colors.accentGold),
          ),
        ),
      ),
    );
  }
}
