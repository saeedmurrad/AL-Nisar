import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/gold_card.dart';
import '../widgets/home_grid_icons.dart';
import '../widgets/irshad_of_the_day_card.dart';
import '../widgets/mandala_painter.dart';
import '../widgets/murshid_avatar.dart';
import '../widgets/social_connect_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.profile?.displayName.trim().isNotEmpty == true
        ? auth.profile!.displayName
        : (auth.user?.displayName ?? 'Member');
    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _Header(
            memberName: name,
            onBellTap: () => context.push('/notifications'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                const IrshadOfTheDayCard(),
                const SizedBox(height: 16),
                const SocialConnectSection(),
                const SizedBox(height: 16),
                _HomeGrid(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.memberName,
    required this.onBellTap,
  });

  final String memberName;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: c.backgroundSurface,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const DrawerMenuButton(),
            const SizedBox(width: 10),
            const MurshidAvatar(
              diameter: 40,
              goldRingWidth: 1.5,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'As-Salaam-Alaikum',
                    style: TextStyle(
                      color: c.textMuted.o(0.95),
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    memberName,
                    style: AppTheme.cinzelHeading(
                      fontSize: 16,
                      letterSpacing: 1.2,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onBellTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.backgroundElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: c.borderDefault,
                    width: 0.5,
                  ),
                ),
                child: SvgPicture.string(
                  _bellSvg,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    c.accentGold,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final c = context.c;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.12,
      children: [
        if (showAdminPanel)
          _HomeGridCard(
            label: 'Admin panel',
            sublabel: 'Manage content',
            iconKind: HomeGridIconKind.adminPanel,
            accent: c.accentGold,
            onTap: onAdminPanel,
          ),
        if (showAsbaqTareeqat)
          _HomeGridCard(
            label: 'Asbaq-e-Tareeqat',
            sublabel: 'Spiritual lessons',
            iconKind: HomeGridIconKind.asbaqTareeqat,
            accent: c.accentGold,
            onTap: onAsbaqTareeqat,
          ),
        _HomeGridCard(
          label: 'Sabaq',
          sublabel: 'Lessons',
          iconKind: HomeGridIconKind.sabaqLessons,
          accent: c.accentGold,
          onTap: onSabaq,
        ),
        _HomeGridCard(
          label: 'Books',
          sublabel: 'Sacred readings',
          iconKind: HomeGridIconKind.books,
          accent: c.accentGold,
          onTap: onBooks,
        ),
        _HomeGridCard(
          label: 'Irshadat',
          sublabel: 'Daily guidance',
          iconKind: HomeGridIconKind.irshadat,
          accent: c.accentGold,
          onTap: onIrshad,
        ),
        _HomeGridCard(
          label: 'News & Events',
          sublabel: 'Updates & gatherings',
          iconKind: HomeGridIconKind.newsEvents,
          accent: c.accentGold,
          onTap: onNewsEvents,
        ),
        _HomeGridCard(
          label: 'Shajra Pak',
          sublabel: 'Silsila tree',
          iconKind: HomeGridIconKind.shijraPak,
          accent: c.accentGold,
          onTap: onShajra,
        ),
        _HomeGridCard(
          label: 'Gallery',
          sublabel: 'Sacred visuals',
          iconKind: HomeGridIconKind.gallery,
          accent: c.accentGold,
          onTap: onGallery,
        ),
      ],
    );
  }
}

class _HomeGridCard extends StatelessWidget {
  const _HomeGridCard({
    required this.label,
    required this.sublabel,
    required this.iconKind,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final HomeGridIconKind iconKind;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: GoldCard(
        backgroundColor: c.backgroundSurface,
        child: Stack(
          children: [
            Positioned(
              top: -18,
              right: -10,
              child: CustomPaint(
                painter: MandalaPainter(
                  opacity: 0.06,
                  strokeWidth: 0.9,
                  rings: 4,
                  petals: 12,
                ),
                size: const Size(120, 120),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HomeGridIcon(kind: iconKind, color: accent, size: 40),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: AppTheme.cinzelHeading(
                    fontSize: 15,
                    letterSpacing: 1.2,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _bellSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M18 16H6c1.1-1.3 1.5-2.8 1.5-4.8 0-3 1.7-5.2 4.5-5.9 2.8.7 4.5 2.9 4.5 5.9 0 2 .4 3.5 1.5 4.8z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/><path d="M10 17.5c.4 1.2 1.2 2 2 2s1.6-.8 2-2" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>';

