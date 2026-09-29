import 'package:flutter/material.dart';

import '../models/tafseer_search.dart';
import '../theme/app_layout.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../utils/urdu_digits.dart';
import '../widgets/gold_card.dart';
import '../widgets/tafseer_html.dart';

/// One search result: where it is, and the matching passage with the query
/// highlighted in place.
class TafseerSearchResultCard extends StatelessWidget {
  const TafseerSearchResultCard({
    super.key,
    required this.hit,
    required this.onTap,
  });

  final TafseerSearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final snippet = hit.snippet();
    final isAyah = hit.kind == TafseerMatchKind.ayah;

    final base = TextStyle(
      fontFamily: isAyah ? tafseerArabicFamily : tafseerUrduFamily,
      fontSize: isAyah ? 15 : 14,
      height: isAyah ? 1.9 : 2.0,
      color: c.textSecondary,
    );
    final hit_ = base.copyWith(
      color: c.accentGold,
      fontWeight: FontWeight.w700,
      backgroundColor: c.accentGold.o(0.14),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppLayout.cardRadius,
          onTap: onTap,
          child: GoldCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _KindTag(kind: hit.kind),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          '${hit.surahNameUrdu} · رکوع ${toUrduDigits(hit.rukuNumber)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: tafseerUrduFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.9,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.accentGold, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        hit.rukuTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: tafseerUrduFamily,
                          fontSize: 12,
                          height: 1.9,
                          color: c.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: snippet.text.substring(0, snippet.start),
                              style: base,
                            ),
                            TextSpan(
                              text: snippet.text
                                  .substring(snippet.start, snippet.end),
                              style: hit_,
                            ),
                            TextSpan(
                              text: snippet.text.substring(snippet.end),
                              style: base,
                            ),
                          ],
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KindTag extends StatelessWidget {
  const _KindTag({required this.kind});

  final TafseerMatchKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.accentGold.o(0.13),
        borderRadius: BorderRadius.circular(AppLayout.radiusPill),
        border: Border.all(color: c.accentGold.o(0.55)),
      ),
      child: Text(
        kind.label,
        style: TextStyle(
          fontFamily: tafseerUrduFamily,
          fontSize: 10.5,
          height: 1.8,
          color: c.accentGold,
        ),
      ),
    );
  }
}
