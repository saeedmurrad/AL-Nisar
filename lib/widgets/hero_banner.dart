import 'package:flutter/material.dart';

class HeroBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? backgroundAsset;
  final Color? backgroundColor;
  final Widget? overlayContent;
  final double height;

  const HeroBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.backgroundAsset,
    this.backgroundColor,
    this.overlayContent,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black87,
        image: backgroundAsset != null
            ? DecorationImage(
                image: AssetImage(backgroundAsset!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Dark overlay for better text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          // Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 44,
                          letterSpacing: 2,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1,
                            ),
                      ),
                    ),
                  ],
                  if (overlayContent != null) ...[
                    const SizedBox(height: 24),
                    overlayContent!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? accentColor;

  const FeatureCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          color: accent.withValues(alpha: 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 40, color: accent),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class IslamicQuote extends StatelessWidget {
  final String quote;
  final String? attribution;
  final bool showDecoration;

  const IslamicQuote({
    super.key,
    required this.quote,
    this.attribution,
    this.showDecoration = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.primaryColor.withValues(alpha: 0.08),
        border: Border(
          left: BorderSide(
            color: theme.primaryColor,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDecoration)
            Text(
              '❖',
              style: TextStyle(
                fontSize: 28,
                color: theme.primaryColor,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            quote,
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
              fontStyle: FontStyle.italic,
              height: 1.6,
              letterSpacing: 0.3,
            ),
          ),
          if (attribution != null) ...[
            const SizedBox(height: 12),
            Text(
              '— $attribution',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
