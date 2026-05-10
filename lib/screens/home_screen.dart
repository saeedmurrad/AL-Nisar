import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../data/dummy_data.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/gold_card.dart';
import '../widgets/home_grid_icons.dart';
import '../widgets/mandala_painter.dart';
import '../widgets/murshid_avatar.dart';
import '../widgets/shimmer_placeholder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final irshad = DummyData.irshadList.first;
    final auth = context.watch<AuthProvider>();
    final name = auth.profile?.displayName.trim().isNotEmpty == true
        ? auth.profile!.displayName
        : (auth.user?.displayName ?? 'Member');
    final showAsbaq = auth.isAdminOrHigher;

    return Scaffold(
      body: Column(
        children: [
          _Header(
            memberName: name,
            onBellTap: () {},
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                _IrshadHeroCard(
                  urduQuote: irshad.urdu,
                  attribution: '— Hazrat Sufi Nisar Ahmed',
                ),
                const SizedBox(height: 16),
                _HomeGrid(
                  showAsbaq: showAsbaq,
                  onAsbaq: () => context.go('/asbaq'),
                  onBooks: () => context.go('/books'),
                  onIrshad: () => context.go('/irshadat'),
                  onNewsEvents: () => context.go('/news-events'),
                  onShijra: () => context.go('/shijra'),
                  onGallery: () => context.go('/gallery'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
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

class _IrshadHeroCard extends StatelessWidget {
  const _IrshadHeroCard({
    required this.urduQuote,
    required this.attribution,
  });

  final String urduQuote;
  final String attribution;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GoldCard(
      backgroundColor: c.backgroundInput,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: CachedNetworkImage(
                  imageUrl: DummyData.tilePattern,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerPlaceholder(),
                  errorWidget: (context, url, error) => const GoldPatternError(),
                ),
              ),
            ),
            Positioned(
              top: -32,
              right: -18,
              child: CustomPaint(
                painter: MandalaPainter(
                  opacity: 0.09,
                  strokeWidth: 1,
                  rings: 5,
                  petals: 14,
                ),
                size: const Size(160, 160),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IRSHAD OF THE DAY',
                    style: TextStyle(
                      color: c.textMuted.o(0.95),
                      letterSpacing: 2.2,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      urduQuote,
                      style: AppTheme.amiriUrdu(
                        fontSize: 18,
                        color: c.textSecondary,
                        height: 2.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      attribution,
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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

class _HomeGrid extends StatelessWidget {
  const _HomeGrid({
    required this.showAsbaq,
    required this.onAsbaq,
    required this.onBooks,
    required this.onIrshad,
    required this.onNewsEvents,
    required this.onShijra,
    required this.onGallery,
  });

  final bool showAsbaq;
  final VoidCallback onAsbaq;
  final VoidCallback onBooks;
  final VoidCallback onIrshad;
  final VoidCallback onNewsEvents;
  final VoidCallback onShijra;
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
        if (showAsbaq)
          _HomeGridCard(
            label: 'Asbaq-e-Tareeqat',
            sublabel: 'Spiritual lessons',
            iconKind: HomeGridIconKind.asbaqTareeqat,
            accent: c.accentGold,
            onTap: onAsbaq,
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
          label: 'Shijra Pak',
          sublabel: 'Silsila tree',
          iconKind: HomeGridIconKind.shijraPak,
          accent: c.accentGold,
          onTap: onShijra,
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

