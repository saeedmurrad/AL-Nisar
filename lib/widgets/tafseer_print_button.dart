import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';

/// Prints the whole surah. Available to every signed-in reader.
///
/// Unlike [TafseerCopyButton] this carries no role gate — any member may take
/// a paper copy away with them.
///
/// It must be its own widget rather than an inline subtree: the shell header
/// re-themes its children to the on-emerald chrome tokens, and only a widget
/// that reads `context.c` in its *own* build picks that up.
class TafseerPrintButton extends StatelessWidget {
  const TafseerPrintButton({
    super.key,
    required this.onPrint,
    this.busy = false,
  });

  final VoidCallback onPrint;

  /// While the surah's rukus are being gathered, show a spinner in place of
  /// the icon so a second tap cannot start a second print.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final gold = context.c.accentGold;
    return IconButton(
      onPressed: busy ? null : onPrint,
      tooltip: 'Print this surah',
      icon: busy
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: gold),
            )
          : Icon(Icons.print_outlined, color: gold, size: 22),
    );
  }
}
