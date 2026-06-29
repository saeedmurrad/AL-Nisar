import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import '../theme/app_theme_colors.dart';

/// Shared top-bar surface: background, safe area, bottom hairline.
class AppShellChrome extends StatelessWidget {
  const AppShellChrome({
    super.key,
    required this.child,
    this.padding = AppLayout.shellPadding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.backgroundSurface,
        border: Border(
          bottom: BorderSide(color: c.borderDefault, width: 0.5),
        ),
      ),
      padding: padding,
      child: SafeArea(
        bottom: false,
        child: child,
      ),
    );
  }
}
