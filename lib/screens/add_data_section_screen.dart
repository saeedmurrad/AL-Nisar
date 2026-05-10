import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/gold_card.dart';

class AddDataSectionScreen extends StatelessWidget {
  const AddDataSectionScreen({super.key});

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
                      'Add Data Section',
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
                  'Choose what you want to add',
                  style: AppTheme.lato(
                    fontSize: 12,
                    color: c.textMuted.o(0.95),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _DataTypeTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Books',
                  subtitle: 'Add your own book PDFs for reading and bookmarks',
                  onTap: () => context.push('/profile/add-data/books'),
                ),
                const SizedBox(height: 10),
                GoldCard(
                  backgroundColor: c.backgroundSurface,
                  child: Text(
                    'More data types can be added here in the future.',
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

class _DataTypeTile extends StatelessWidget {
  const _DataTypeTile({
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

