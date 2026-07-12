import 'package:flutter/material.dart';

import '../theme/color_utils.dart';
import '../utils/responsive_layout.dart';
import 'app_nav_panel.dart';
import 'islamic_ui.dart';

/// Web/desktop chrome around every signed-in screen.
///
/// On expanded viewports it shows a persistent side navigation and centers
/// the page in a capped-width column; on phones it renders the page as-is
/// (screens keep their own drawer + header).
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.isExpanded(context)) {
      return child;
    }

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: ResponsiveLayout.sideNavWidth,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kEmeraldSoft, kEmerald, kDeepEmerald],
              ),
              border: Border(
                right: BorderSide(color: kHeroGold.o(0.35), width: 0.8),
              ),
            ),
            child: Theme(
              data: emeraldChromeTheme(context),
              child: const SafeArea(child: AppNavPanel()),
            ),
          ),
          // Full width beside the nav: header bands span edge-to-edge like a
          // website navbar; each page caps its own content column.
          Expanded(child: child),
        ],
      ),
    );
  }
}
