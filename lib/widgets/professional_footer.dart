import 'package:flutter/material.dart';

class ProfessionalFooter extends StatelessWidget {
  final String? title;
  final List<FooterSection>? sections;
  final List<SocialLink>? socialLinks;
  final String? copyrightText;

  const ProfessionalFooter({
    super.key,
    this.title,
    this.sections,
    this.socialLinks,
    this.copyrightText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(
            color: theme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (sections != null && sections!.isNotEmpty) ...[
            Wrap(
              spacing: 40,
              runSpacing: 24,
              children: sections!
                  .map(
                    (section) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...section.links
                            .map(
                              (link) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: link.onTap,
                                  child: Text(
                                    link.text,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (socialLinks != null && socialLinks!.isNotEmpty) ...[
            Wrap(
              spacing: 16,
              children: socialLinks!
                  .map(
                    (link) => InkWell(
                      onTap: link.onTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.primaryColor.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          link.icon,
                          size: 20,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          Container(
            height: 1,
            color: theme.primaryColor.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            copyrightText ?? '© 2024 Al-Nisar. All rights reserved.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class FooterSection {
  final String title;
  final List<FooterLink> links;

  FooterSection({
    required this.title,
    required this.links,
  });
}

class FooterLink {
  final String text;
  final VoidCallback? onTap;

  FooterLink({
    required this.text,
    this.onTap,
  });
}

class SocialLink {
  final IconData icon;
  final VoidCallback? onTap;

  SocialLink({
    required this.icon,
    this.onTap,
  });
}

class StatsSection extends StatelessWidget {
  final List<StatCard> stats;

  const StatsSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: stats
              .map(
                (stat) => Expanded(
                  child: StatCard(
                    number: stat.number,
                    label: stat.label,
                    icon: stat.icon,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData? icon;

  const StatCard({
    super.key,
    required this.number,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
        color: theme.primaryColor.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32, color: theme.primaryColor),
            const SizedBox(height: 8),
          ],
          Text(
            number,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
