import 'package:flutter/material.dart';

import '../navigation/go_router_helpers.dart';
import '../theme/app_layout.dart';
import '../theme/app_theme.dart';
import 'app_shell_chrome.dart';
import 'islamic_ui.dart';

/// Top bar for shell screens: **Back** (via [popOrGoHome]), title, optional trailing and bottom row.
class StandardShellHeader extends StatelessWidget {
  const StandardShellHeader({
    super.key,
    this.title = '',
    this.titleWidget,
    this.trailing,
    this.bottom,
    this.padding = AppLayout.shellPadding,
    this.showBack = true,
    this.onBack,
    this.disableBack = false,
  });

  final String title;
  final Widget? titleWidget;
  final Widget? trailing;
  final Widget? bottom;
  final EdgeInsets padding;
  final bool showBack;
  final VoidCallback? onBack;
  final bool disableBack;

  @override
  Widget build(BuildContext context) {
    // The header sits on the fixed emerald chrome band, so its own inline
    // styles use the on-emerald tokens (theme overrides only affect widgets
    // built *below* AppShellChrome, not styles computed in this method).
    return AppShellChrome(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBack)
                IconButton(
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  onPressed: disableBack
                      ? null
                      : (onBack ?? () => popOrGoHome(context)),
                  icon: Icon(
                    Icons.arrow_back,
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
          if (bottom case final b?) b,
        ],
      ),
    );
  }
}
