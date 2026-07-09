import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';
import '../utils/responsive_layout.dart';
import 'app_nav_panel.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Drawer(
      backgroundColor: c.backgroundSurface,
      child: SafeArea(
        child: AppNavPanel(onNavigated: () => Navigator.of(context).pop()),
      ),
    );
  }
}

/// Opens the drawer on phones/tablets; hidden on desktop where the
/// persistent side navigation is always visible.
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isExpanded(context)) {
      return const SizedBox.shrink();
    }
    final c = context.c;
    return InkWell(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.backgroundElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.borderDefault, width: 0.5),
        ),
        child: Icon(Icons.menu_rounded, size: 20, color: c.accentGold),
      ),
    );
  }
}
