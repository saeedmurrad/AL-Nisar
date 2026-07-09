import 'package:flutter/material.dart';

import '../models/social_links_config.dart';
import '../services/social_links_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../utils/external_link_launcher.dart';
import 'gold_card.dart';

class SocialConnectSection extends StatelessWidget {
  const SocialConnectSection({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SocialLinksService();

    return StreamBuilder<SocialLinksConfig>(
      stream: service.streamConfig(),
      builder: (context, snap) {
        final config = snap.data ?? SocialLinksConfig.defaults;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FacebookCard(config: config),
            const SizedBox(height: 12),
            _YouTubeCard(config: config),
          ],
        );
      },
    );
  }
}

class _FacebookCard extends StatelessWidget {
  const _FacebookCard({required this.config});

  final SocialLinksConfig config;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return GoldCard(
      backgroundColor: c.backgroundInput,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.backgroundElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.borderDefault, width: 0.5),
                ),
                child: Icon(
                  Icons.facebook_rounded,
                  color: c.accentGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facebook Page',
                      style: AppTheme.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sufi Nisar Ahmad',
                      style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (config.showFacebookLiveBanner) ...[
            const SizedBox(height: 12),
            _LiveBanner(
              label: 'Watch Live on Facebook',
              onTap: () => launchFacebookUrl(
                context,
                config.facebookLiveUrl,
                failureMessage: 'Could not open Facebook live',
              ),
            ),
          ],
          const SizedBox(height: 12),
          _SocialActionButton(
            label: 'Visit Facebook Page',
            icon: Icons.open_in_new_rounded,
            onTap: () => launchFacebookUrl(
              context,
              config.facebookPageUrl,
              failureMessage: 'Could not open Facebook page',
            ),
          ),
        ],
      ),
    );
  }
}

class _YouTubeCard extends StatelessWidget {
  const _YouTubeCard({required this.config});

  final SocialLinksConfig config;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return GoldCard(
      backgroundColor: c.backgroundInput,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.backgroundElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.borderDefault, width: 0.5),
                ),
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  color: c.accentGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YouTube Channel',
                      style: AppTheme.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@sufinisarahmad159',
                      style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SocialActionButton(
            label: 'Visit YouTube Channel',
            icon: Icons.open_in_new_rounded,
            onTap: () => launchYouTubeUrl(
              context,
              config.youtubeChannelUrl,
              failureMessage: 'Could not open YouTube channel',
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBanner extends StatelessWidget {
  const _LiveBanner({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: c.accentGold.o(0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.accentGold.o(0.55), width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).o(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.accentGold,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 18, color: c.accentGold),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialActionButton extends StatelessWidget {
  const _SocialActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: c.backgroundSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.borderDefault, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: c.accentGold),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
