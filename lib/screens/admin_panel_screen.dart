import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/gold_card.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: c.backgroundSurface,
            padding: const EdgeInsets.fromLTRB(10, 18, 16, 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back, color: c.accentGold),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Admin Panel',
                      style: AppTheme.cinzelHeading(fontSize: 18),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) context.go('/login');
                    },
                    child: Text(
                      'Sign out',
                      style: AppTheme.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                if (auth.isSuperAdmin) ...[
                  _Tile(
                    icon: Icons.verified_user_outlined,
                    title: 'Super Admin Panel',
                    subtitle: 'Users, roles, and elevated controls',
                    onTap: () => context.push('/super-admin'),
                  ),
                  const SizedBox(height: 10),
                ],
                _Tile(
                  icon: Icons.menu_book_outlined,
                  title: 'Upload Books',
                  subtitle: 'Upload PDFs + metadata to Firebase',
                  onTap: () => context.push('/admin/books'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Add Data',
                  subtitle: 'Books, Irshadat, Sabaq/Asbaq, News & Events',
                  onTap: () => context.push('/admin/add-data'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.auto_stories_outlined,
                  title: 'Manage Irshadat',
                  subtitle: 'Create daily guidance cards',
                  onTap: () => context.push('/admin/irshadat'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.library_books_outlined,
                  title: 'Manage Sabaq',
                  subtitle: 'Upload Sabaq PDF + titles + thumbnail',
                  onTap: () => context.push('/admin/sabaq'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.mark_email_unread_outlined,
                  title: 'Sabaq Access Requests',
                  subtitle: 'Approve member requests to unlock Sabaq PDFs',
                  onTap: () => context.push('/admin/sabaq-requests'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.lock_open_outlined,
                  title: 'Manage Asbaq-e-Tareeqat',
                  subtitle: 'Upload Asbaq PDF + titles + thumbnail',
                  onTap: () => context.push('/admin/asbaq'),
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

