import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../utils/responsive_layout.dart';
import 'app_nav_panel.dart';
import 'islamic_ui.dart';
import 'notification_bell_button.dart';

/// Web/desktop chrome around every signed-in screen.
///
/// On expanded viewports it shows a persistent (collapsible) side navigation,
/// a slim top utility bar with the collapse toggle and a profile menu, and
/// the page beneath. On phones it renders the page as-is (screens keep their
/// own drawer + header).
class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key, required this.child});

  final Widget child;

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.isExpanded(context)) {
      return widget.child;
    }

    final navWidth = _collapsed
        ? ResponsiveLayout.sideNavCollapsedWidth
        : ResponsiveLayout.sideNavWidth;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: navWidth,
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
              child: SafeArea(
                child: AppNavPanel(collapsed: _collapsed),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _DesktopTopBar(
                  collapsed: _collapsed,
                  onToggle: () => setState(() => _collapsed = !_collapsed),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slim emerald utility bar above every desktop page. It uses the same top
/// gradient stop as the page headers so the two read as one chrome region.
class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.collapsed, required this.onToggle});

  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveLayout.desktopTopBarHeight,
      color: kEmeraldSoft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Theme(
        data: emeraldChromeTheme(context),
        child: Row(
          children: [
            IconButton(
              tooltip: collapsed ? 'Expand menu' : 'Collapse menu',
              onPressed: onToggle,
              icon: Icon(
                collapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                color: kHeroGold,
              ),
            ),
            const Spacer(),
            NotificationBellButton(
              onTap: () => context.push('/notifications'),
            ),
            const SizedBox(width: 12),
            const _ProfileMenuButton(),
          ],
        ),
      ),
    );
  }
}

enum _ProfileAction { profile, notifications, signOut }

class _ProfileMenuButton extends StatelessWidget {
  const _ProfileMenuButton();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.profile?.displayName.trim().isNotEmpty == true
        ? auth.profile!.displayName
        : (auth.user?.displayName ?? 'Member');
    final email = auth.profile?.email ?? auth.user?.email ?? '';
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'M';

    return PopupMenuButton<_ProfileAction>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      color: kEmerald,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: kHeroGold.o(0.35)),
      ),
      onSelected: (action) async {
        switch (action) {
          case _ProfileAction.profile:
            context.go('/profile');
          case _ProfileAction.notifications:
            context.push('/notifications');
          case _ProfileAction.signOut:
            await context.read<AuthProvider>().signOut();
            if (context.mounted) context.go('/login');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_ProfileAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.cormorantGaramond(
                  fontSize: 17,
                  color: kHeroCream,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.lato(
                    fontSize: 11,
                    color: kHeroCream.o(0.6),
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        _menuRow(_ProfileAction.profile, Icons.person_outline, 'My Profile'),
        _menuRow(
          _ProfileAction.notifications,
          Icons.notifications_none_rounded,
          'Notifications',
        ),
        _menuRow(_ProfileAction.signOut, Icons.logout_rounded, 'Sign out'),
      ],
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kEmerald,
          border: Border.all(color: kHeroGold, width: 1.4),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: AppTheme.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kHeroGold,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_ProfileAction> _menuRow(
    _ProfileAction action,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<_ProfileAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 19, color: kHeroGold),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTheme.lato(fontSize: 13.5, color: kHeroCream),
          ),
        ],
      ),
    );
  }
}
