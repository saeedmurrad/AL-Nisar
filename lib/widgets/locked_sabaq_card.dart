import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme_colors.dart';
import 'gold_card.dart';

class LockedSabaqCard extends StatelessWidget {
  const LockedSabaqCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pageCount,
  });

  final String title;
  final String subtitle;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Opacity(
      opacity: 0.5,
      child: GoldCard(
        backgroundColor: c.backgroundSurface,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: c.backgroundElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.borderDefault, width: 0.5),
              ),
              child: Center(
                child: SvgPicture.string(
                  _lockSvg,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(c.accentGold, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 14,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$pageCount pages • Locked',
                    style: TextStyle(color: c.textFaint, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _lockSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M7.5 11V8.7A4.5 4.5 0 0 1 12 4.2a4.5 4.5 0 0 1 4.5 4.5V11" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/><path d="M7 11h10a1.5 1.5 0 0 1 1.5 1.5v6A1.5 1.5 0 0 1 17 20H7a1.5 1.5 0 0 1-1.5-1.5v-6A1.5 1.5 0 0 1 7 11z" fill="none" stroke="currentColor" stroke-width="1.6"/></svg>';
