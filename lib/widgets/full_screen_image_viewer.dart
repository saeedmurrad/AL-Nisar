import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import 'shimmer_placeholder.dart';

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    this.caption,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final String? caption;

  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    required int initialIndex,
    String? caption,
  }) {
    if (imageUrls.isEmpty) return Future.value();
    final index = initialIndex.clamp(0, imageUrls.length - 1);
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: index,
          caption: caption,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final urls = widget.imageUrls;
    final caption = widget.caption?.trim();

    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: urls.length,
            onPageChanged: (value) => setState(() => _index = value),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(urls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4.0,
                initialScale: PhotoViewComputedScale.contained,
              );
            },
            backgroundDecoration: BoxDecoration(color: c.backgroundPrimary),
            loadingBuilder: (context, event) => const Center(
              child: ShimmerPlaceholder(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                children: [
                  _OverlayButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.string(
                      _closeSvg,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        c.accentGold,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (urls.length > 1)
                    Text(
                      '${_index + 1}/${urls.length}',
                      style: AppTheme.lato(
                        fontSize: 12,
                        color: c.textMuted,
                        letterSpacing: 1.1,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.backgroundElevated.o(0.82),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.borderDefault, width: 0.5),
                  ),
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: AppTheme.lato(
                      fontSize: 12,
                      color: c.textPrimary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.backgroundElevated.o(0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.borderDefault, width: 0.5),
        ),
        child: child,
      ),
    );
  }
}

const _closeSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M6 6l12 12M18 6L6 18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>';
