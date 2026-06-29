import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import 'gold_card.dart';
import 'ornament_divider.dart';

class BrandedStateView extends StatelessWidget {
  const BrandedStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.lg),
        child: GoldCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppLayout.sm),
                  child: CircularProgressIndicator(color: c.accentGold),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accentGold.o(0.12),
                    border: Border.all(color: c.accentGold.o(0.35)),
                  ),
                  child: Icon(icon, color: c.accentGold, size: 28),
                ),
              const SizedBox(height: AppLayout.md),
              const OrnamentDivider(),
              const SizedBox(height: AppLayout.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.cormorantGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppLayout.xs),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTheme.lato(
                    fontSize: 13,
                    color: c.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppLayout.md),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
