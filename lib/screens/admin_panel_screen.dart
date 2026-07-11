import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/gold_card.dart';
import '../widgets/screen_navigation_header.dart';
import '../widgets/islamic_ui.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          ScreenNavigationHeader(
            title: 'Admin Panel',
            padding: const EdgeInsets.fromLTRB(4, 18, 8, 12),
            trailing: TextButton(
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) context.go('/login');
              },
              child: Text(
                'Sign out',
                style: AppTheme.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kOnEmeraldColors.accentGold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                if (auth.isSuperAdmin) ...[
                  _SectionLabel('Administration'),
                  _Tile(
                    icon: Icons.verified_user_outlined,
                    title: 'Super Admin Panel',
                    subtitle: 'Users, roles, and member requests',
                    onTap: () => context.push('/super-admin'),
                  ),
                  const SizedBox(height: 16),
                ],
                const _SectionLabel('Content'),
                _Tile(
                  icon: Icons.auto_stories_outlined,
                  title: 'Manage Irshadat',
                  subtitle: 'Create and edit Irshad Pak cards (Urdu & English)',
                  onTap: () => context.push('/admin/irshadat'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.photo_library_outlined,
                  title: 'Upload Gallery Images',
                  subtitle: 'Upload images and organize albums',
                  onTap: () => context.push('/admin/gallery'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.menu_book_outlined,
                  title: 'Books',
                  subtitle: 'Upload PDFs and book metadata',
                  onTap: () => context.push('/admin/books'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.event_note_outlined,
                  title: 'News & Events',
                  subtitle: 'Publish news articles and event announcements',
                  onTap: () => context.push('/admin/news-events'),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.account_tree_outlined,
                  title: 'Shajra Urdu Details',
                  subtitle: 'Upload Urdu biography PDFs by personality',
                  onTap: () => context.push('/admin/shajra-urdu'),
                ),
                const SizedBox(height: 16),
                const _SectionLabel('App settings'),
                _Tile(
                  icon: Icons.share_outlined,
                  title: 'Social Links',
                  subtitle: 'Facebook, YouTube, and live stream banner',
                  onTap: () => context.push('/admin/social-links'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.lato(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c.textMuted,
          letterSpacing: 1.4,
        ),
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
