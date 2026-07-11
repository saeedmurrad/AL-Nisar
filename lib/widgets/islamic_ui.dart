import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../utils/responsive_layout.dart';
import 'murshid_avatar.dart';
import 'ornament_divider.dart';

/// Fixed palette for the hero and footer surfaces. These are deliberately
/// theme-independent: a deep emerald night with gold accents reads richly in
/// both light and dark modes, like the header bands on classic Sufi sites.
const kDeepEmerald = Color(0xFF07150F);
const kEmerald = Color(0xFF0E2B1F);
const kEmeraldSoft = Color(0xFF16382A);
const kHeroGold = Color(0xFFD4AF37);
const kHeroCream = Color(0xFFF4EDDE);

/// On-emerald theme tokens: wrap chrome surfaces (top bar, drawer, sidebar)
/// in `Theme(data: emeraldChromeTheme(context), ...)` and every descendant
/// that reads `context.c` automatically recolors for the dark emerald band.
const kOnEmeraldColors = AppThemeColors(
  backgroundPrimary: kDeepEmerald,
  backgroundSurface: kEmerald,
  backgroundElevated: Color(0xFF1B3D2E),
  backgroundInput: Color(0xFF123024),
  accentGold: kHeroGold,
  textPrimary: kHeroCream,
  textSecondary: Color(0xFFDCE8DC),
  textMuted: Color(0xFF9DBBA8),
  textFaint: Color(0xFF6E8F7C),
  borderDefault: Color(0xFF2E5949),
  borderFaint: Color(0xFF1C3A2C),
);

ThemeData emeraldChromeTheme(BuildContext context) =>
    Theme.of(context).copyWith(extensions: const [kOnEmeraldColors]);

/// A call-to-action shown on the hero banner.
class HeroAction {
  const HeroAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// Full-width hero: deep emerald gradient, geometric star lattice, Bismillah,
/// serif title, and optional CTAs. Height is padding-driven (never overflows,
/// even with large font-scale settings).
class IslamicHeroBanner extends StatelessWidget {
  const IslamicHeroBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.bismillah = true,
    this.showAvatar = false,
    this.primaryAction,
    this.secondaryAction,
  });

  final String title;
  final String? subtitle;
  final bool bismillah;
  final bool showAvatar;
  final HeroAction? primaryAction;
  final HeroAction? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final w = ResponsiveLayout.screenWidth(context);
    final isMobile = w < ResponsiveLayout.mediumWidth;
    final isDesktop = w >= ResponsiveLayout.expandedWidth;

    final titleSize = isMobile ? 34.0 : (isDesktop ? 52.0 : 44.0);
    final vPad = isMobile ? 36.0 : (isDesktop ? 56.0 : 46.0);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 0 : 18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kEmeraldSoft, kEmerald, kDeepEmerald],
        ),
        border: isMobile
            ? null
            : Border.all(color: kHeroGold.o(0.25), width: 0.8),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _HeroPatternPainter()),
          ),
          // Soft gold glow behind the content.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [kHeroGold.o(0.10), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 40,
              vertical: vPad,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showAvatar) ...[
                  const MurshidAvatar(diameter: 92, goldRingWidth: 2),
                  const SizedBox(height: 18),
                ],
                if (bismillah) ...[
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: AppTheme.amiriUrdu(
                      fontSize: isMobile ? 17 : 21,
                      color: kHeroGold,
                      height: 1.9,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTheme.cormorantGaramond(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500,
                    color: kHeroCream,
                    letterSpacing: isMobile ? 3 : 6,
                  ),
                ),
                const SizedBox(height: 14),
                const OrnamentDivider(
                  color: kHeroGold,
                  mutedColor: Color(0x66D4AF37),
                ),
                if (subtitle case final s?) ...[
                  const SizedBox(height: 14),
                  Text(
                    s,
                    textAlign: TextAlign.center,
                    style: AppTheme.lato(
                      fontSize: isMobile ? 13 : 15,
                      color: kHeroCream.o(0.82),
                      letterSpacing: 1.2,
                      height: 1.6,
                    ),
                  ),
                ],
                if (primaryAction != null || secondaryAction != null) ...[
                  SizedBox(height: isMobile ? 22 : 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (primaryAction case final a?)
                        _HeroButton(action: a, filled: true),
                      if (secondaryAction case final a?)
                        _HeroButton(action: a, filled: false),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.action, required this.filled});

  final HeroAction action;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      action.label,
      style: AppTheme.lato(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: filled ? kDeepEmerald : kHeroGold,
      ),
    );
    const shape = StadiumBorder();
    const pad = EdgeInsets.symmetric(horizontal: 26, vertical: 14);

    return filled
        ? ElevatedButton(
            onPressed: action.onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: kHeroGold,
              foregroundColor: kDeepEmerald,
              elevation: 0,
              shape: shape,
              padding: pad,
            ),
            child: label,
          )
        : OutlinedButton(
            onPressed: action.onTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kHeroGold.o(0.7), width: 1),
              shape: shape,
              padding: pad,
            ),
            child: label,
          );
  }
}

/// Subtle eight-pointed-star lattice + scattered star dots for hero/footer.
class _HeroPatternPainter extends CustomPainter {
  const _HeroPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = kHeroGold.o(0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    const cell = 86.0;
    final cols = (size.width / cell).ceil() + 1;
    final rows = (size.height / cell).ceil() + 1;

    for (var r = 0; r < rows; r++) {
      for (var col = 0; col < cols; col++) {
        final cx = col * cell + (r.isOdd ? cell / 2 : 0);
        final cy = r * cell;
        _drawEightPointStar(canvas, stroke, Offset(cx, cy), 16);
      }
    }

    // Scattered "night sky" dots, deterministic layout.
    final dot = Paint()..color = kHeroCream.o(0.16);
    for (var i = 0; i < 60; i++) {
      final fx = ((i * 9301 + 49297) % 233280) / 233280;
      final fy = ((i * 6551 + 20011) % 104729) / 104729;
      final radius = 0.5 + ((i * 37) % 3) * 0.35;
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        radius,
        dot,
      );
    }
  }

  void _drawEightPointStar(
    Canvas canvas,
    Paint paint,
    Offset center,
    double r,
  ) {
    for (final rotation in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rotation + i * math.pi / 2;
        final p = Offset(
          center.dx + r * math.cos(a),
          center.dy + r * math.sin(a),
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPatternPainter oldDelegate) => false;
}

/// Centered ornamental section header: small gold caption, serif title,
/// optional Urdu line, ornament underneath.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.caption,
    required this.title,
    this.urdu,
  });

  final String caption;
  final String title;
  final String? urdu;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isMobile =
        ResponsiveLayout.screenWidth(context) < ResponsiveLayout.mediumWidth;

    return Column(
      children: [
        Text(
          caption.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTheme.sectionCaption(
            color: c.accentGold,
            letterSpacing: 2.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTheme.cormorantGaramond(
            fontSize: isMobile ? 24 : 28,
            color: c.textPrimary,
            letterSpacing: 0.8,
          ),
        ),
        if (urdu case final u?) ...[
          const SizedBox(height: 2),
          Text(
            u,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTheme.amiriUrdu(
              fontSize: 15,
              color: c.textMuted,
              height: 1.6,
            ),
          ),
        ],
        const SizedBox(height: 10),
        const OrnamentDivider(),
      ],
    );
  }
}

/// Full-width quote band with oversized quotation mark and attribution.
class QuoteBand extends StatelessWidget {
  const QuoteBand({super.key, required this.quote, this.attribution});

  final String quote;
  final String? attribution;

  @override
  Widget build(BuildContext context) {
    final isMobile =
        ResponsiveLayout.screenWidth(context) < ResponsiveLayout.mediumWidth;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kEmeraldSoft, kEmerald, kDeepEmerald],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 34 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Text(
                '❝',
                style: AppTheme.cormorantGaramond(
                  fontSize: 44,
                  color: kHeroGold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                quote,
                textAlign: TextAlign.center,
                style: AppTheme.cormorantGaramond(
                  fontSize: isMobile ? 20 : 25,
                  color: kHeroCream,
                  height: 1.5,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
              if (attribution case final a?) ...[
                const SizedBox(height: 14),
                Text(
                  '—  $a  —',
                  style: AppTheme.sectionCaption(
                    color: kHeroGold.o(0.9),
                    letterSpacing: 2.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One footer navigation entry.
class FooterLink {
  const FooterLink(this.label, this.route);

  final String label;
  final String route;
}

/// Site footer: brand, navigation, verse, copyright — on deep emerald.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key, this.links = defaultLinks});

  final List<FooterLink> links;

  static const defaultLinks = <FooterLink>[
    FooterLink('Home', '/home'),
    FooterLink('Sabaq', '/sabaq'),
    FooterLink('Books', '/books'),
    FooterLink('Irshadat', '/irshadat'),
    FooterLink('News & Events', '/news-events'),
    FooterLink('Shajra Pak', '/shijra'),
    FooterLink('Gallery', '/gallery'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile =
        ResponsiveLayout.screenWidth(context) < ResponsiveLayout.mediumWidth;

    return Container(
      width: double.infinity,
      color: kDeepEmerald,
      padding: EdgeInsets.fromLTRB(24, isMobile ? 34 : 46, 24, 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              Text(
                'AL Nisar',
                style: AppTheme.cormorantGaramond(
                  fontSize: 26,
                  color: kHeroGold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SPIRITUAL LEARNINGS',
                style: AppTheme.sectionCaption(
                  color: kHeroCream.o(0.55),
                  fontSize: 10,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 2,
                children: [
                  for (final link in links)
                    TextButton(
                      onPressed: () => context.go(link.route),
                      style: TextButton.styleFrom(
                        foregroundColor: kHeroCream.o(0.78),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        link.label,
                        style: AppTheme.lato(
                          fontSize: 12.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const OrnamentDivider(
                color: kHeroGold,
                mutedColor: Color(0x4DD4AF37),
              ),
              const SizedBox(height: 18),
              Text(
                '“Verily, in the remembrance of Allah do hearts find rest.”',
                textAlign: TextAlign.center,
                style: AppTheme.cormorantGaramond(
                  fontSize: 16,
                  color: kHeroCream.o(0.85),
                  height: 1.5,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              Text(
                'AL-QUR’AN 13:28',
                style: AppTheme.sectionCaption(
                  color: kHeroCream.o(0.45),
                  fontSize: 9.5,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 22),
              Container(height: 0.6, color: kHeroCream.o(0.12)),
              const SizedBox(height: 14),
              Text(
                '© 2026 AL Nisar · All rights reserved',
                style: AppTheme.lato(
                  fontSize: 11,
                  color: kHeroCream.o(0.5),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
