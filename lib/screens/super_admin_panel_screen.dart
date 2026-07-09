import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/gold_card.dart';
import '../widgets/screen_navigation_header.dart';

class SuperAdminPanelScreen extends StatelessWidget {
  const SuperAdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isSuperAdmin) {
      Future.microtask(() {
        if (context.mounted) context.go('/home');
      });
    }

    return Scaffold(
      body: Column(
        children: [
          const ScreenNavigationHeader(
            title: 'Super Admin Panel',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 12),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                _Tile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'New member requests and alerts',
                  onTap: () => context.push('/notifications'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.people_outline,
                  title: 'Users',
                  subtitle: 'View all users and promote to Admin',
                  onTap: () => context.push('/super-admin/users'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.mark_email_unread_outlined,
                  title: 'Sabaq Access Requests',
                  subtitle: 'Approve member requests to unlock Sabaq PDFs',
                  onTap: () => context.push('/admin/sabaq-requests'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: GoldCard(
        backgroundColor: c.backgroundSurface,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.backgroundElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.borderDefault, width: 0.5),
              ),
              child: Icon(icon, color: c.accentGold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.accentGold),
          ],
        ),
      ),
    );
  }
}
