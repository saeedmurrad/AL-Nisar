import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/auth_screen_decor.dart';
import '../widgets/murshid_avatar.dart';
import '../widgets/ornament_divider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _t;
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );
    _fadeController.forward();

    _t = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go('/home');
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: AuthScreenDecor(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
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
                      style: AppTheme.displayTitle(
                        fontSize: 22,
                        letterSpacing: 1.2,
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
                      style: AppTheme.sectionCaption(
                        color: c.textMuted,
                        letterSpacing: 3,
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
