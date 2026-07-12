import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../utils/responsive_layout.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_shell_chrome.dart';
import '../widgets/home_grid_icons.dart';
import '../widgets/irshad_of_the_day_card.dart';
import '../widgets/islamic_ui.dart';
import '../widgets/murshid_avatar.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/social_connect_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.profile?.displayName.trim().isNotEmpty == true
        ? auth.profile!.displayName
        : (auth.user?.displayName ?? 'Member');

    final isMedium = ResponsiveLayout.isMedium(context);
    final hPad = EdgeInsets.symmetric(horizontal: isMedium ? 24.0 : 16.0);

    return Scaffold(
      drawer: ResponsiveLayout.isExpanded(context) ? null : const AppDrawer(),
      body: Column(
        children: [
          _Header(
            memberName: name,
            onBellTap: () => context.push('/notifications'),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Hero ────────────────────────────────────────────────
                Padding(
                  // Full-bleed on phones; inset card on tablet/desktop.
                  padding: isMedium
                      ? const EdgeInsets.fromLTRB(24, 20, 24, 0)
                      : EdgeInsets.zero,
                  child: IslamicHeroBanner(
                    title: 'AL Nisar',
                    subtitle:
                        'A sanctuary of spiritual wisdom, sacred knowledge,\n'
                        'and the remembrance of Allah',
                    showAvatar: true,
                    primaryAction: HeroAction(
                      label: 'BEGIN YOUR SABAQ',
                      onTap: () => context.go('/sabaq'),
                    ),
                    secondaryAction: HeroAction(
                      label: 'SACRED BOOKS',
                      onTap: () => context.go('/books'),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Daily guidance ─────────────────────────────────────
                const SectionHeader(
                  caption: 'Daily Guidance',
                  title: 'Irshad of the Day',
                  urdu: 'ارشادِ پاک',
                ),
                const SizedBox(height: 18),
                ContentColumn(
                  maxWidth: 720,
                  child: Padding(
                    padding: hPad,
                    child: const IrshadOfTheDayCard(),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Quote band ─────────────────────────────────────────
                const QuoteBand(
                  quote:
                      'The heart is a mirror — polish it with the '
                      'remembrance of God.',
                  attribution: 'Sufi Wisdom',
                ),
                const SizedBox(height: 36),

                // ── Explore grid ───────────────────────────────────────
                const SectionHeader(
                  caption: 'Explore',
                  title: 'The Path of Knowledge',
                  urdu: 'علم کا راستہ',
                ),
                const SizedBox(height: 18),
                ContentColumn(
                  maxWidth: ResponsiveLayout.contentMaxWidth,
                  child: Padding(
                    padding: hPad,
                    child: _HomeGrid(
                      showAdminPanel: auth.isAdminOrHigher,
                      onAdminPanel: () => context.go('/admin'),
                      showAsbaqTareeqat: auth.isAdminOrHigher,
                      onAsbaqTareeqat: () => context.go('/asbaq'),
                      onSabaq: () => context.go('/sabaq'),
                      onBooks: () => context.go('/books'),
                      onIrshad: () => context.go('/irshadat'),
                      onNewsEvents: () => context.go('/news-events'),
                      onShajra: () => context.go('/shijra'),
                      onGallery: () => context.go('/gallery'),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Community ──────────────────────────────────────────
                const SectionHeader(
                  caption: 'Stay Connected',
                  title: 'Join Our Community',
                ),
                const SizedBox(height: 18),
                ContentColumn(
                  maxWidth: 720,
                  child: Padding(
                    padding: hPad,
                    child: const SocialConnectSection(),
                  ),
                ),
                const SizedBox(height: 44),

                // ── Footer ─────────────────────────────────────────────
                const AppFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.memberName, required this.onBellTap});

  final String memberName;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    return AppShellChrome(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          if (!ResponsiveLayout.isExpanded(context)) ...const [
            DrawerMenuButton(),
            SizedBox(width: 10),
          ],
          const MurshidAvatar(diameter: 40, goldRingWidth: 1.5),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'As-Salaam-Alaikum',
                  style: AppTheme.sectionCaption(
                    color: kHeroGold.o(0.9),
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  memberName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTheme.displayTitle(
                    fontSize: 17,
                    color: kHeroCream,
                  ),
                ),
              ],
            ),
          ),
          NotificationBellButton(onTap: onBellTap),
        ],
      ),
    );
  }
}

class _HomeGrid extends StatelessWidget {
  const _HomeGrid({
    required this.showAdminPanel,
    required this.onAdminPanel,
    required this.showAsbaqTareeqat,
    required this.onAsbaqTareeqat,
    required this.onSabaq,
    required this.onBooks,
    required this.onIrshad,
    required this.onNewsEvents,
    required this.onShajra,
    required this.onGallery,
  });

  final bool showAdminPanel;
  final VoidCallback onAdminPanel;
  final bool showAsbaqTareeqat;
  final VoidCallback onAsbaqTareeqat;
  final VoidCallback onSabaq;
  final VoidCallback onBooks;
  final VoidCallback onIrshad;
  final VoidCallback onNewsEvents;
  final VoidCallback onShajra;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = ResponsiveLayout.gridColumns(context);
        final cellWidth = (constraints.maxWidth - 12 * (cols - 1)) / cols;
        // Uniform card height regardless of viewport width.
        final ratio = (cellWidth / 172).clamp(0.9, 2.1);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: ratio,
          children: [
        if (showAdminPanel)
          _HomeGridCard(
            label: 'Admin Panel',
            sublabel: 'Manage content',
            iconKind: HomeGridIconKind.adminPanel,
            onTap: onAdminPanel,
          ),
        if (showAsbaqTareeqat)
          _HomeGridCard(
            label: 'Asbaq-e-Tareeqat',
            sublabel: 'Spiritual lessons',
            iconKind: HomeGridIconKind.asbaqTareeqat,
            onTap: onAsbaqTareeqat,
          ),
        _HomeGridCard(
          label: 'Sabaq',
          sublabel: 'Lessons',
          iconKind: HomeGridIconKind.sabaqLessons,
          onTap: onSabaq,
        ),
        _HomeGridCard(
          label: 'Books',
          sublabel: 'Sacred readings',
          iconKind: HomeGridIconKind.books,
          onTap: onBooks,
        ),
        _HomeGridCard(
          label: 'Irshadat',
          sublabel: 'Daily guidance',
          iconKind: HomeGridIconKind.irshadat,
          onTap: onIrshad,
        ),
        _HomeGridCard(
          label: 'News & Events',
          sublabel: 'Updates & gatherings',
          iconKind: HomeGridIconKind.newsEvents,
          onTap: onNewsEvents,
        ),
        _HomeGridCard(
          label: 'Shajra Pak',
          sublabel: 'Silsila tree',
          iconKind: HomeGridIconKind.shijraPak,
          onTap: onShajra,
        ),
            _HomeGridCard(
              label: 'Gallery',
              sublabel: 'Sacred visuals',
              iconKind: HomeGridIconKind.gallery,
              onTap: onGallery,
            ),
          ],
        );
      },
    );
  }
}

/// Medallion-style destination card: gold-ringed icon, centered serif label.
class _HomeGridCard extends StatelessWidget {
  const _HomeGridCard({
    required this.label,
    required this.sublabel,
    required this.iconKind,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final HomeGridIconKind iconKind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipTop = c.accentGold;
    final chipBottom =
        Color.lerp(c.accentGold, isDark ? Colors.black : Colors.white, 0.22)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: c.backgroundSurface,
            border: Border.all(color: c.borderFaint, width: 1),
            boxShadow: [
              BoxShadow(
                color: c.accentGold.o(isDark ? 0.10 : 0.14),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [chipBottom, chipTop],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.accentGold.o(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: HomeGridIcon(
                      kind: iconKind,
                      color: isDark ? kDeepEmerald : Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTheme.cinzelHeading(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sublabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTheme.lato(color: c.textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
