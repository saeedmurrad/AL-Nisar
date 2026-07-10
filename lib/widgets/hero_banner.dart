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
    final isMobile = MediaQuery.of(context).size.width < 700;
    final isTablet = MediaQuery.of(context).size.width < 1024;

    // Responsive font sizes
    final titleFontSize = isMobile ? 32.0 : (isTablet ? 38.0 : 44.0);
    final subtitleFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final titleSpacing = isMobile ? 1.0 : (isTablet ? 1.5 : 2.0);

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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: titleFontSize,
                            letterSpacing: titleSpacing,
                          ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: isMobile ? 12 : 16),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white70,
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w300,
                              letterSpacing: isMobile ? 0.5 : 1,
                            ),
                      ),
                    ],
                    if (overlayContent != null) ...[
                      SizedBox(height: isMobile ? 16 : 24),
                      overlayContent!,
                    ],
                  ],
                ),
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
    final isMobile = MediaQuery.of(context).size.width < 700;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
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
              Icon(icon, size: isMobile ? 32 : 40, color: accent),
              SizedBox(height: isMobile ? 8 : 12),
            ],
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : 16,
                letterSpacing: 0.5,
              ),
            ),
            if (description != null) ...[
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
                  fontSize: isMobile ? 12 : 13,
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
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                fontSize: isMobile ? 24 : 28,
                color: theme.primaryColor,
              ),
            ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            quote,
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
              fontStyle: FontStyle.italic,
              fontSize: isMobile ? 15 : 18,
              height: 1.6,
              letterSpacing: isMobile ? 0.2 : 0.3,
            ),
          ),
          if (attribution != null) ...[
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              '— $attribution',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
