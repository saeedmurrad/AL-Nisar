import 'package:flutter/material.dart';

import '../navigation/go_router_helpers.dart';
import '../theme/app_layout.dart';
import '../theme/app_theme.dart';
import 'app_shell_chrome.dart';
import 'islamic_ui.dart';

/// Top bar with working **Back** (pop or dashboard) and **Home**, plus title and optional trailing.
class ScreenNavigationHeader extends StatelessWidget {
  const ScreenNavigationHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.trailing,
    this.padding = AppLayout.shellPadding,
    this.onBack,
    this.onHome,
    this.backEnabled = true,
    this.homeEnabled = true,
    this.disableBack = false,
  });

  final String title;
  final Widget? titleWidget;
  final Widget? trailing;
  final EdgeInsets padding;
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final bool backEnabled;
  final bool homeEnabled;

  /// When true, the back arrow is visible but not tappable (e.g. during save).
  final bool disableBack;

  @override
  Widget build(BuildContext context) {
    // On the fixed emerald band — use on-emerald tokens for inline styles.
    return AppShellChrome(
      padding: padding,
      child: Row(
        children: [
          if (backEnabled)
            IconButton(
              tooltip: 'Back',
              onPressed: disableBack
                  ? null
                  : (onBack ?? () => popOrGoHome(context)),
              icon: Icon(
                Icons.arrow_back,
                color: kOnEmeraldColors.accentGold,
              ),
            ),
          if (homeEnabled)
            IconButton(
              tooltip: 'Home',
              onPressed: onHome ?? () => goAppHome(context),
              icon: Icon(
                Icons.home_outlined,
                color: kOnEmeraldColors.accentGold,
              ),
            ),
          Expanded(
            child:
                titleWidget ??
                Text(
                  title,
                  style: AppTheme.displayTitle(
                    fontSize: 22,
                    color: kOnEmeraldColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
          ),
          if (trailing case final t?) t,
        ],
      ),
    );
  }
}
