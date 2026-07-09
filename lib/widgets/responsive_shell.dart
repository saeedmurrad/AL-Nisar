import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';
import '../utils/responsive_layout.dart';
import 'app_nav_panel.dart';

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

    final c = context.c;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: ResponsiveLayout.sideNavWidth,
            decoration: BoxDecoration(
              color: c.backgroundSurface,
              border: Border(
                right: BorderSide(color: c.borderDefault, width: 0.5),
              ),
            ),
            child: const SafeArea(child: AppNavPanel()),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: ResponsiveLayout.contentMaxWidth,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
