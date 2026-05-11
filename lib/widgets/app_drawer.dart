import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';

class _DrawerDestination {
  const _DrawerDestination({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}

List<_DrawerDestination> _memberDestinationsFor(AuthProvider auth) => [
  const _DrawerDestination(route: '/home', label: 'Home', icon: Icons.home_outlined),
  const _DrawerDestination(route: '/sabaq', label: 'Sabaq', icon: Icons.menu_book_outlined),
  if (auth.isAdminOrHigher)
    const _DrawerDestination(route: '/asbaq', label: 'Asbaaq-e-Tareeqat', icon: Icons.auto_stories_outlined),
  const _DrawerDestination(route: '/books', label: 'Books', icon: Icons.library_books_outlined),
  const _DrawerDestination(route: '/irshadat', label: 'Irshadat', icon: Icons.favorite_outline),
  const _DrawerDestination(route: '/news-events', label: 'News & Events', icon: Icons.event_note_outlined),
  const _DrawerDestination(route: '/shijra', label: 'Shajra Pak', icon: Icons.account_tree_outlined),
  const _DrawerDestination(route: '/gallery', label: 'Gallery', icon: Icons.grid_view_outlined),
  const _DrawerDestination(route: '/bookmarks', label: 'Bookmarks', icon: Icons.bookmark_outline),
  const _DrawerDestination(route: '/profile', label: 'Profile', icon: Icons.person_outline),
];

const _adminPanelDestination = _DrawerDestination(
  route: '/admin',
  label: 'Admin panel',
  icon: Icons.admin_panel_settings_outlined,
);

List<_DrawerDestination> _destinationsFor(AuthProvider auth) {
  final member = _memberDestinationsFor(auth);
  if (auth.isAdminOrHigher) {
    return [
      member.first,
      _adminPanelDestination,
      ...member.skip(1),
    ];
  }
  return [...member];
}

bool _isRouteSelected(String route, String location) {
  if (route == '/admin') {
    return location == '/admin' ||
        location.startsWith('/admin/') ||
        location == '/super-admin' ||
        location.startsWith('/super-admin/');
  }
  if (route == '/shijra') {
    return location == '/shijra' ||
        location.startsWith('/shijra/') ||
        location == '/shajra' ||
        location.startsWith('/shajra/');
  }
  return location == route || location.startsWith('$route/');
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.watch<AuthProvider>();
    final destinations = _destinationsFor(auth);
    final location = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: c.backgroundSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'AL Nisar',
                style: AppTheme.cinzelHeading(
                  fontSize: 20,
                  letterSpacing: 1.4,
                  color: c.textPrimary,
                ),
              ),
            ),
            Divider(height: 1, color: c.borderDefault),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final d in destinations)
                    _DrawerTile(
                      destination: d,
                      selected: _isRouteSelected(d.route, location),
                      onTap: () {
                        context.go(d.route);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _DrawerDestination destination;
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

class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
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
