import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../auth/auth_provider.dart';
import '../data/dummy_data.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/gold_card.dart';
import '../widgets/mandala_painter.dart';
import '../widgets/murshid_avatar.dart';
import '../widgets/ornament_divider.dart';
import '../widgets/shimmer_placeholder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google sign-in failed',
            style: AppTheme.lato(color: context.c.textPrimary),
          ),
          backgroundColor: context.c.backgroundElevated,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                children: [
                  const Spacer(),
                  const MurshidAvatar(
                    diameter: 112,
                    goldRingWidth: 2.5,
                    outerRingWidth: 4,
                    applyGoldenOverlay: true,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'AL Nisar',
                    style: AppTheme.cinzelHeading(
                      fontSize: 22,
                      letterSpacing: 3,
                      color: c.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Spiritual Learnings',
                    style: AppTheme.lato(
                      fontSize: 13,
                      color: c.textMuted.o(0.95),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const OrnamentDivider(),
                  const SizedBox(height: 18),
                  GoldCard(
                    backgroundColor: c.backgroundSurface.o(0.9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome back',
                          style: AppTheme.cormorantGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to access lessons, Irshadat, and your saved content.',
                          style: AppTheme.lato(
                            fontSize: 12,
                            color: c.textMuted,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.accentGold,
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? c.backgroundPrimary
                                    : c.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? c.backgroundPrimary
                                        : c.textPrimary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.g_mobiledata,
                                      size: 26,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? c.backgroundPrimary
                                          : c.textPrimary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Continue with Google',
                                      style: AppTheme.lato(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Admin features appear automatically when your role is upgraded.',
                          textAlign: TextAlign.center,
                          style: AppTheme.lato(
                            fontSize: 11.5,
                            color: c.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'By continuing, you agree to sign in with your Google account.',
                    textAlign: TextAlign.center,
                    style: AppTheme.lato(fontSize: 11, color: c.textFaint),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

