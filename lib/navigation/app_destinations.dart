import 'package:flutter/material.dart';

import '../auth/auth_provider.dart';

/// A primary navigation destination, shown in the drawer (mobile) and the
/// persistent side navigation (desktop/web).
class AppDestination {
  const AppDestination({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}

List<AppDestination> _memberDestinationsFor(AuthProvider auth) => [
  const AppDestination(
    route: '/home',
    label: 'Home',
    icon: Icons.home_outlined,
  ),
  const AppDestination(
    route: '/sabaq',
    label: 'Sabaq',
    icon: Icons.menu_book_outlined,
  ),
  if (auth.isAdminOrHigher)
    const AppDestination(
      route: '/asbaq',
      label: 'Asbaaq-e-Tareeqat',
      icon: Icons.auto_stories_outlined,
    ),
  const AppDestination(
    route: '/books',
    label: 'Books',
    icon: Icons.library_books_outlined,
  ),
  const AppDestination(
    route: '/irshadat',
    label: 'Irshadat',
    icon: Icons.favorite_outline,
  ),
  const AppDestination(
    route: '/news-events',
    label: 'News & Events',
    icon: Icons.event_note_outlined,
  ),
  const AppDestination(
    route: '/shijra',
    label: 'Shajra Pak',
    icon: Icons.account_tree_outlined,
  ),
  const AppDestination(
    route: '/gallery',
    label: 'Gallery',
    icon: Icons.grid_view_outlined,
  ),
  const AppDestination(
    route: '/bookmarks',
    label: 'Bookmarks',
    icon: Icons.bookmark_outline,
  ),
  const AppDestination(
    route: '/profile',
    label: 'Profile',
    icon: Icons.person_outline,
  ),
];

const _adminPanelDestination = AppDestination(
  route: '/admin',
  label: 'Admin Panel',
  icon: Icons.admin_panel_settings_outlined,
);

List<AppDestination> appDestinationsFor(AuthProvider auth) {
  final member = _memberDestinationsFor(auth);
  if (auth.isAdminOrHigher) {
    return [member.first, _adminPanelDestination, ...member.skip(1)];
  }
  return [...member];
}

bool isAppRouteSelected(String route, String location) {
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
