import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/dummy_data.dart';
import '../models/irshad_firestore_model.dart';
import '../services/irshad_daily_picker.dart';
import '../services/irshad_share_service.dart';
import '../services/irshadat_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import 'full_screen_image_viewer.dart';
import 'gold_card.dart';
import 'ornament_divider.dart';
import 'shimmer_placeholder.dart';

/// Daily Irshad from `irshadat_ur` — random pick seeded by local calendar date.
class IrshadOfTheDayCard extends StatefulWidget {
  const IrshadOfTheDayCard({super.key});

  @override
  State<IrshadOfTheDayCard> createState() => _IrshadOfTheDayCardState();
}

class _IrshadOfTheDayCardState extends State<IrshadOfTheDayCard> {
  final _service = IrshadatService();
  final _shareService = IrshadShareService();
  StreamSubscription<List<IrshadFirestoreModel>>? _sub;
  List<IrshadFirestoreModel> _urdu = [];
  bool _sharing = false;

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

  List<IrshadFirestoreModel> _effectiveList() {
    if (_urdu.isNotEmpty) return _urdu;
    return DummyData.irshadList
        .map(
          (d) => IrshadFirestoreModel(
            id: d.dateLabel,
            dateLabel: d.dateLabel,
            text: d.urdu,
            imageUrl: '',
            createdAt: DateTime.now(),
            isActive: true,
          ),
        )
        .toList();
  }

  String _resolveImageUrl(IrshadFirestoreModel? ir) {
    final url = ir?.imageUrl.trim() ?? '';
    return url.isNotEmpty ? url : DummyData.calligraphyClose;
  }

  Future<void> _share(IrshadFirestoreModel ir) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await _shareService.share(
        ir: ir,
        language: IrshadatLanguage.urdu,
        dateLabelOverride: IrshadDailyPicker.todayLabel(),
        irshadPakOfTheDay: true,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _effectiveList();
    final pick = IrshadDailyPicker.pickForDay(list);
    final loading = _urdu.isEmpty && list.isEmpty;
    final todayLabel = IrshadDailyPicker.todayLabel();

    return _UrduIrshadPhotoCard(
      ir: pick,
      imageUrl: _resolveImageUrl(pick),
      loading: loading,
      sharing: _sharing,
      todayLabel: todayLabel,
      onShare: pick == null ? null : () => _share(pick),
    );
  }
}

class _UrduIrshadPhotoCard extends StatelessWidget {
  const _UrduIrshadPhotoCard({
    required this.ir,
    required this.imageUrl,
    required this.loading,
    required this.sharing,
    required this.todayLabel,
    required this.onShare,
  });

  final IrshadFirestoreModel? ir;
  final String imageUrl;
  final bool loading;
  final bool sharing;
  final String todayLabel;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasText = ir?.text.trim().isNotEmpty == true;

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
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Irshad Pak of the Day',
                      style: AppTheme.cinzelHeading(
                        fontSize: 15,
                        letterSpacing: 1.1,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  if (!loading && onShare != null)
                    IconButton(
                      onPressed: sharing ? null : onShare,
                      tooltip: 'Share',
                      icon: sharing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.accentGold,
                              ),
                            )
                          : SvgPicture.string(
                              _shareSvg,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                c.accentGold,
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                ],
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
            if (!loading && ir != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  todayLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (hasText) ...[
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: OrnamentDivider(),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      ir!.text,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.amiriUrdu(
                        fontSize: 16,
                        height: 2.0,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 12),
            ],
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
      caption: todayLabel,
    );
  }
}

const _shareSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M16 7l-8 4 8 4" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/><path d="M18 9.2a2.2 2.2 0 1 0 0-4.4 2.2 2.2 0 0 0 0 4.4zM6 13.2a2.2 2.2 0 1 0 0-4.4 2.2 2.2 0 0 0 0 4.4zM18 19.2a2.2 2.2 0 1 0 0-4.4 2.2 2.2 0 0 0 0 4.4z" fill="none" stroke="currentColor" stroke-width="1.6"/></svg>';
