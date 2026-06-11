import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../models/irshad_firestore_model.dart';
import '../services/irshadat_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import 'full_screen_image_viewer.dart';
import 'gold_card.dart';
import 'shimmer_placeholder.dart';

/// Daily Urdu Irshad photo from `irshadat_ur` (rotates by local calendar date).
class IrshadOfTheDayCard extends StatefulWidget {
  const IrshadOfTheDayCard({super.key});

  @override
  State<IrshadOfTheDayCard> createState() => _IrshadOfTheDayCardState();
}

class _IrshadOfTheDayCardState extends State<IrshadOfTheDayCard> {
  final _service = IrshadatService();
  StreamSubscription<List<IrshadFirestoreModel>>? _sub;
  List<IrshadFirestoreModel> _urdu = [];

  @override
  void initState() {
    super.initState();
    _sub = _service.streamIrshadat(IrshadatLanguage.urdu).listen((list) {
      if (mounted) setState(() => _urdu = list);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<IrshadFirestoreModel> _sortedForDailyPick() {
    final copy = List<IrshadFirestoreModel>.from(_urdu);
    copy.sort((a, b) => a.id.compareTo(b.id));
    return copy;
  }

  int _pickIndex(int length, DateTime localNow) {
    if (length <= 0) return 0;
    final key = localNow.year * 10000 + localNow.month * 100 + localNow.day;
    return key % length;
  }

  String _resolveImageUrl(IrshadFirestoreModel? ir) {
    final url = ir?.imageUrl.trim() ?? '';
    return url.isNotEmpty ? url : DummyData.calligraphyClose;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedForDailyPick();
    final pick = sorted.isEmpty ? null : sorted[_pickIndex(sorted.length, DateTime.now())];
    final imageUrl = _resolveImageUrl(pick);

    return _UrduIrshadPhotoCard(
      imageUrl: imageUrl,
      loading: sorted.isEmpty && _urdu.isEmpty,
    );
  }
}

class _UrduIrshadPhotoCard extends StatelessWidget {
  const _UrduIrshadPhotoCard({
    required this.imageUrl,
    required this.loading,
  });

  final String imageUrl;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return GoldCard(
      backgroundColor: c.backgroundInput,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Text(
                'Irshad of the Day',
                style: AppTheme.cinzelHeading(
                  fontSize: 15,
                  letterSpacing: 1.1,
                  color: c.textPrimary,
                ),
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Material(
                color: c.backgroundInput,
                child: InkWell(
                  onTap: loading ? null : () => _openFullscreen(context),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (loading)
                        const ShimmerPlaceholder()
                      else
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          filterQuality: FilterQuality.high,
                          placeholder: (context, url) => const ShimmerPlaceholder(),
                          errorWidget: (context, url, error) => CachedNetworkImage(
                            imageUrl: DummyData.calligraphyClose,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            filterQuality: FilterQuality.high,
                            placeholder: (context, url) => const ShimmerPlaceholder(),
                            errorWidget: (context, url, error) => const GoldPatternError(),
                          ),
                        ),
                      if (!loading)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: c.backgroundPrimary.o(0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.borderDefault, width: 0.5),
                            ),
                            child: Icon(
                              Icons.fullscreen_rounded,
                              size: 18,
                              color: c.accentGold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    FullScreenImageViewer.open(
      context,
      imageUrls: [imageUrl],
      initialIndex: 0,
    );
  }
}
