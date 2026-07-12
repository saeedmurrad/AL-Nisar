import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../navigation/app_destinations.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/mandala_painter.dart';

/// Navigation panel body shared by the mobile [Drawer] and the persistent
/// desktop side navigation: brand header, destinations, appearance controls.
///
/// When [collapsed] is true (desktop rail) it shows icon-only tiles with
/// tooltips and hides the brand wordmark and appearance row.
class AppNavPanel extends StatelessWidget {
  const AppNavPanel({super.key, this.onNavigated, this.collapsed = false});

  /// Called after a destination is opened (the drawer uses this to close).
  final VoidCallback? onNavigated;

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.watch<AuthProvider>();
    final destinations = appDestinationsFor(auth);
    final location = GoRouterState.of(context).uri.path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (collapsed)
          const SizedBox(height: 14)
        else
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -20,
                top: -10,
                child: Opacity(
                  opacity: 0.08,
                  child: CustomPaint(
                    painter: MandalaPainter(
                      color: c.accentGold,
                      opacity: 0.08,
                      strokeWidth: 0.8,
                      rings: 3,
                      petals: 10,
                    ),
                    size: const Size(100, 100),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'AL Nisar',
                  style: AppTheme.displayTitle(
                    fontSize: 22,
                    letterSpacing: 2.4,
                    color: c.accentGold,
                  ),
                ),
              ),
            ],
          ),
        Divider(height: 1, color: c.borderDefault),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final d in destinations)
                _NavTile(
                  destination: d,
                  selected: isAppRouteSelected(d.route, location),
                  collapsed: collapsed,
                  onTap: () {
                    context.go(d.route);
                    onNavigated?.call();
                  },
                ),
            ],
          ),
        ),
        Divider(height: 1, color: c.borderDefault),
        // Minimal footer: just the light/dark toggle. Color themes and font
        // size live in Profile → Appearance.
        Padding(
          padding: collapsed
              ? const EdgeInsets.symmetric(vertical: 14)
              : const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: collapsed
              ? const Center(child: ThemeToggleButton())
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appearance',
                      style: AppTheme.lato(
                        fontSize: 12,
                        color: c.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.collapsed = false,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = selected ? c.accentGold : c.textSecondary;

    final tile = Material(
      color: selected ? c.backgroundElevated : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: collapsed ? 14 : 12,
          ),
          child: collapsed
              ? Icon(destination.icon, size: 24, color: fg)
              : Row(
                  children: [
                    Icon(destination.icon, size: 22, color: fg),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.lato(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: fg.o(selected ? 1.0 : 0.95),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 8, vertical: 2),
      child: collapsed
          ? Tooltip(message: destination.label, child: tile)
          : tile,
    );
  }
}
