import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../models/irshad_firestore_model.dart';
import '../services/irshadat_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import 'gold_card.dart';
import 'mandala_painter.dart';
import 'shimmer_placeholder.dart';

class _TaggedIrshad {
  const _TaggedIrshad({required this.lang, required this.model});

  final IrshadatLanguage lang;
  final IrshadFirestoreModel model;
}

/// Deterministic daily pick from merged Urdu + English Firestore feeds (local calendar date).
class IrshadOfTheDayCard extends StatefulWidget {
  const IrshadOfTheDayCard({super.key});

  @override
  State<IrshadOfTheDayCard> createState() => _IrshadOfTheDayCardState();
}

class _IrshadOfTheDayCardState extends State<IrshadOfTheDayCard> {
  final _service = IrshadatService();
  StreamSubscription<List<IrshadFirestoreModel>>? _subUr;
  StreamSubscription<List<IrshadFirestoreModel>>? _subEn;
  List<IrshadFirestoreModel> _ur = [];
  List<IrshadFirestoreModel> _en = [];

  @override
  void initState() {
    super.initState();
    _subUr = _service.streamIrshadat(IrshadatLanguage.urdu).listen((l) {
      if (mounted) setState(() => _ur = l);
    });
    _subEn = _service.streamIrshadat(IrshadatLanguage.english).listen((l) {
      if (mounted) setState(() => _en = l);
    });
  }

  @override
  void dispose() {
    _subUr?.cancel();
    _subEn?.cancel();
    super.dispose();
  }

  List<_TaggedIrshad> _mergedSorted() {
    final out = <_TaggedIrshad>[
      ..._ur.map((m) => _TaggedIrshad(lang: IrshadatLanguage.urdu, model: m)),
      ..._en.map((m) => _TaggedIrshad(lang: IrshadatLanguage.english, model: m)),
    ];
    out.sort((a, b) {
      final c = a.lang.name.compareTo(b.lang.name);
      if (c != 0) return c;
      return a.model.id.compareTo(b.model.id);
    });
    return out;
  }

  int _pickIndex(int length, DateTime localNow) {
    if (length <= 0) return 0;
    final key = localNow.year * 10000 + localNow.month * 100 + localNow.day;
    return key % length;
  }

  @override
  Widget build(BuildContext context) {
    final merged = _mergedSorted();
    final localNow = DateTime.now();

    if (merged.isEmpty) {
      final fallback = DummyData.irshadList.first;
      return _IrshadHeroCard(
        quote: fallback.urdu,
        attribution: '— Hazrat Sufi Nisar Ahmed',
        rtl: true,
      );
    }

    final pick = merged[_pickIndex(merged.length, localNow)];
    final text = pick.model.text.trim();
    final quote = text.isNotEmpty
        ? text
        : (pick.lang == IrshadatLanguage.urdu
            ? DummyData.irshadList.first.urdu
            : DummyData.irshadList.first.english);

    return _IrshadHeroCard(
      quote: quote,
      attribution: pick.model.dateLabel.trim().isNotEmpty
          ? pick.model.dateLabel
          : '— Hazrat Sufi Nisar Ahmed',
      rtl: pick.lang.isRtl,
      imageUrl: pick.model.imageUrl.trim(),
    );
  }
}

class _IrshadHeroCard extends StatelessWidget {
  const _IrshadHeroCard({
    required this.quote,
    required this.attribution,
    required this.rtl,
    this.imageUrl,
  });

  final String quote;
  final String attribution;
  final bool rtl;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bg =
        (imageUrl != null && imageUrl!.trim().isNotEmpty) ? imageUrl!.trim() : DummyData.tilePattern;

    return GoldCard(
      backgroundColor: c.backgroundInput,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: CachedNetworkImage(
                  imageUrl: bg,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerPlaceholder(),
                  errorWidget: (context, url, error) => CachedNetworkImage(
                    imageUrl: DummyData.tilePattern,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerPlaceholder(),
                    errorWidget: (context, url, error) => const GoldPatternError(),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -32,
              right: -18,
              child: CustomPaint(
                painter: MandalaPainter(
                  opacity: 0.09,
                  strokeWidth: 1,
                  rings: 5,
                  petals: 14,
                ),
                size: const Size(160, 160),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IRSHAD OF THE DAY',
                    style: TextStyle(
                      color: c.textMuted.o(0.95),
                      letterSpacing: 2.2,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  rtl
                      ? Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            quote,
                            style: AppTheme.amiriUrdu(
                              fontSize: 18,
                              color: c.textSecondary,
                              height: 2.2,
                            ),
                          ),
                        )
                      : Text(
                          quote,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 15,
                            height: 1.65,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      attribution,
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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
