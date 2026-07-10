import 'package:flutter/material.dart';
import '../theme/color_utils.dart';
import '../widgets/hero_banner.dart';
import '../widgets/professional_footer.dart';
import '../widgets/islamic_decoration.dart';

class DesignShowcaseScreen extends StatelessWidget {
  const DesignShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      body: ListView(
        children: [
          // Hero Banner
          HeroBanner(
            title: 'Al-Nisar',
            subtitle: 'Spiritual Wisdom & Islamic Guidance',
            backgroundColor: c.backgroundPrimary,
            height: 280,
          ),

          // Welcome Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to the New Design',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Below you can see all the new professional design components:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Islamic Quote Example
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: IslamicQuote(
              quote:
                  'The heart is a mirror; polish it with the remembrance of God.',
              attribution: 'Sufi Wisdom',
              showDecoration: true,
            ),
          ),

          const SizedBox(height: 24),

          // Feature Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feature Cards',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.book,
                        title: 'Lessons',
                        description: 'Spiritual teachings and guidance',
                        accentColor: c.accentGold,
                      ),
                    ),
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.photo,
                        title: 'Gallery',
                        description: 'Sacred visuals and moments',
                        accentColor: c.accentGold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Islamic Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: IslamicDivider(height: 24),
          ),

          // Statistics Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics Cards',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: c.accentGold.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          color: c.accentGold.withValues(alpha: 0.05),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.people, size: 32, color: c.accentGold),
                            const SizedBox(height: 8),
                            Text(
                              '1000+',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: c.accentGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Members',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: c.accentGold.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          color: c.accentGold.withValues(alpha: 0.05),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.book, size: 32, color: c.accentGold),
                            const SizedBox(height: 8),
                            Text(
                              '500+',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: c.accentGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lessons',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Color Palette Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Islamic Color Palette',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ColorSwatch(
                      label: 'Primary',
                      color: c.backgroundPrimary,
                    ),
                    _ColorSwatch(
                      label: 'Accent',
                      color: c.accentGold,
                    ),
                    _ColorSwatch(
                      label: 'Text',
                      color: c.textPrimary,
                    ),
                    _ColorSwatch(
                      label: 'Border',
                      color: c.borderDefault,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorSwatch({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
