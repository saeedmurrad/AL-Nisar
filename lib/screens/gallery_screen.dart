import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../data/dummy_data.dart';
import '../models/gallery_image_model.dart';
import '../services/gallery_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/standard_shell_header.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final service = GalleryService();

    return Scaffold(
      body: Column(
        children: [
          const StandardShellHeader(
            title: 'Gallery',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 14),
          ),
          Expanded(
            child: StreamBuilder<List<GalleryImageModel>>(
              stream: service.streamActive(),
              builder: (context, snap) {
                final list = snap.data ?? const <GalleryImageModel>[];
                // Fallback to DummyData if Firebase has nothing yet.
                final urls = list.isNotEmpty
                    ? list.map((e) => e.downloadUrl).toList()
                    : DummyData.galleryImages;

                if (snap.connectionState == ConnectionState.waiting && urls.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: c.accentGold),
                  );
                }

                if (urls.isEmpty) {
                  return Center(
                    child: Text('No images yet', style: AppTheme.lato(color: c.textMuted)),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: urls.length,
                  itemBuilder: (context, i) {
                    final url = urls[i];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                _GalleryViewer(
                                  images: urls,
                                  initialIndex: i,
                                ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                                FadeTransition(opacity: animation, child: child),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => ShimmerPlaceholder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorWidget: (context, url, error) => const GoldPatternError(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _pc;
  int _i = 0;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _i = widget.initialIndex;
    _pc = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pc,
            itemCount: widget.images.length,
            onPageChanged: (v) => setState(() => _i = v),
            builder: (context, i) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(widget.images[i]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.0,
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
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.backgroundElevated.o(0.65),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: c.borderDefault,
                          width: 0.5,
                        ),
                      ),
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
                  ),
                  const Spacer(),
                  Text(
                    '${_i + 1}/${widget.images.length}',
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _sharing ? null : _shareCurrent,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.backgroundElevated.o(0.65),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: c.borderDefault,
                          width: 0.5,
                        ),
                      ),
                      child: _sharing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.accentGold,
                              ),
                            )
                          : Icon(Icons.share, color: c.accentGold, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCurrent() async {
    setState(() => _sharing = true);
    try {
      final url = widget.images[_i];
      final file = await _downloadImageToTemp(url);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      // Ignore; user can retry.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<File> _downloadImageToTemp(String url) async {
    final uri = Uri.parse(url);
    final client = HttpClient();
    final req = await client.getUrl(uri);
    final res = await req.close();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      client.close(force: true);
      throw HttpException('download_failed', uri: uri);
    }
    final bytes = await res.fold<List<int>>(<int>[], (p, e) => p..addAll(e));
    client.close(force: true);
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/gallery_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }
}

const _closeSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M6 6l12 12M18 6L6 18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>';

