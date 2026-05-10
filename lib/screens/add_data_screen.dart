import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/gold_card.dart';

class AddDataScreen extends StatelessWidget {
  const AddDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

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
                      'Add Data',
                      style: AppTheme.cinzelHeading(fontSize: 18),
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
                Text(
                  'Choose what you want to upload',
                  style: AppTheme.lato(
                    fontSize: 12,
                    color: c.textMuted.o(0.95),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Add Books',
                  subtitle: 'Upload book entries (PDF + fields)',
                  onTap: () => context.push('/admin/add-data/books'),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.auto_stories_outlined,
                  title: 'Add Irshadat (English)',
                  subtitle: 'Create Irshadat English entries (+ optional image)',
                  onTap: () => context.push('/admin/add-data/irshadat-english'),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.auto_stories_outlined,
                  title: 'Add Irshadat (Urdu)',
                  subtitle: 'Create Irshadat Urdu entries (+ optional image)',
                  onTap: () => context.push('/admin/add-data/irshadat-urdu'),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.lock_open_outlined,
                  title: 'Add Asbaq e Tareekat',
                  subtitle: 'Upload/manage Asbaq-e-Tareeqat lessons',
                  onTap: () => context.push('/admin/add-data/asbaq'),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.library_books_outlined,
                  title: 'Add Sabaq',
                  subtitle: 'Upload Sabaq PDF + titles + thumbnail',
                  onTap: () => context.push('/admin/add-data/sabaq'),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.event_outlined,
                  title: 'Add News & Events',
                  subtitle: 'Upload news articles and event announcements',
                  onTap: () => context.push('/admin/add-data/news-events'),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.account_tree_outlined,
                  title: 'Add Urdu Shajra Details',
                  subtitle: 'Upload Urdu Shajra PDFs (by personality)',
                  onTap: () => context.push('/admin/add-data/shajra-urdu'),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Upload Gallery Images',
                  subtitle: 'Add high-quality images to the Gallery',
                  onTap: () => context.push('/admin/add-data/gallery'),
                ),
                const SizedBox(height: 10),
                GoldCard(
                  backgroundColor: c.backgroundSurface,
                  child: Text(
                    'Uploads are restricted to Admin/Super Admin.',
                    style: AppTheme.lato(
                      fontSize: 12,
                      color: c.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
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
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.lato(
                      fontSize: 12,
                      color: c.textMuted,
                      height: 1.35,
                    ),
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

