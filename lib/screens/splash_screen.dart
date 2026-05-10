import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../data/dummy_data.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/mandala_painter.dart';
import '../widgets/murshid_avatar.dart';
import '../widgets/ornament_divider.dart';
import '../widgets/shimmer_placeholder.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _pageController = PageController(initialPage: 1);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      // Router redirect will enforce auth (login vs home).
      context.go('/home');
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: c.backgroundPrimary),
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: CachedNetworkImage(
                imageUrl: DummyData.mosqueDomeGold,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerPlaceholder(),
                errorWidget: (context, url, error) => const GoldPatternError(),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: CachedNetworkImage(
                imageUrl: DummyData.candleFlame,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerPlaceholder(),
                errorWidget: (context, url, error) => const GoldPatternError(),
              ),
            ),
          ),
          Center(
            child: Opacity(
              opacity: 0.07,
              child: CustomPaint(
                painter: MandalaPainter(
                  opacity: 0.07,
                  strokeWidth: 1.0,
                  rings: 6,
                  petals: 16,
                ),
                size: const Size(320, 320),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const Spacer(),
                  const MurshidAvatar(
                    diameter: 110,
                    goldRingWidth: 2.5,
                    outerRingWidth: 4,
                    applyGoldenOverlay: true,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Sufi Nisar Ahmed',
                    style: AppTheme.cinzelHeading(
                      fontSize: 20,
                      letterSpacing: 2,
                      color: c.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'صوفی نثار احمد',
                      style: AppTheme.amiriUrdu(
                        fontSize: 18,
                        height: 2.2,
                        color: c.accentGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const OrnamentDivider(),
                  const SizedBox(height: 16),
                  Text(
                    'SPIRITUAL TEACHINGS',
                    style: TextStyle(
                      color: c.textMuted.o(0.95),
                      letterSpacing: 3,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 26),
                  AnimatedSmoothIndicator(
                    activeIndex: 1,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      dotHeight: 7,
                      dotWidth: 7,
                      expansionFactor: 2.8,
                      spacing: 8,
                      dotColor: c.borderDefault.o(0.9),
                      activeDotColor: c.accentGold,
                    ),
                    onDotClicked: (i) {},
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 1,
                    child: PageView(
                      controller: _pageController,
                      children: const [SizedBox(), SizedBox(), SizedBox()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

