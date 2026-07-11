import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import '../theme/color_utils.dart';
import 'islamic_ui.dart';

/// Shared top-bar surface: deep emerald band with a gilded hairline, like a
/// website navbar. Wraps its child in on-emerald theme tokens so titles,
/// search fields, and buttons recolor automatically.
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kEmeraldSoft, kEmerald],
        ),
        border: Border(
          bottom: BorderSide(color: kHeroGold.o(0.45), width: 1),
        ),
      ),
      padding: padding,
      child: SafeArea(
        bottom: false,
        child: Theme(data: emeraldChromeTheme(context), child: child),
      ),
    );
  }
}
