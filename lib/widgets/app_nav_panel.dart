import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../navigation/app_destinations.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/theme_palette_picker.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/font_scale_control.dart';
import '../widgets/mandala_painter.dart';

/// Navigation panel body shared by the mobile [Drawer] and the persistent
/// desktop side navigation: brand header, destinations, appearance controls.
class AppNavPanel extends StatelessWidget {
  const AppNavPanel({super.key, this.onNavigated});

  /// Called after a destination is opened (the drawer uses this to close).
  final VoidCallback? onNavigated;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.watch<AuthProvider>();
    final destinations = appDestinationsFor(auth);
    final location = GoRouterState.of(context).uri.path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  onTap: () {
                    context.go(d.route);
                    onNavigated?.call();
                  },
                ),
            ],
          ),
        ),
        Divider(height: 1, color: c.borderDefault),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance',
                style: AppTheme.lato(
                  fontSize: 12,
                  color: c.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [ThemeToggleButton()],
              ),
              const SizedBox(height: 12),
              const ThemePalettePicker(compact: true),
              const SizedBox(height: 12),
              const FontScaleControl(compact: true),
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
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = selected ? c.accentGold : c.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? c.backgroundElevated : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(destination.icon, size: 22, color: fg),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    destination.label,
                    style: AppTheme.lato(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: fg.o(selected ? 1.0 : 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
