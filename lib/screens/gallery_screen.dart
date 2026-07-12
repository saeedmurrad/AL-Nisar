import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../data/dummy_data.dart';
import '../models/gallery_folder.dart';
import '../models/gallery_image_model.dart';
import '../services/gallery_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../utils/file_bytes_utils.dart';
import '../utils/responsive_layout.dart';
import '../widgets/gold_card.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/islamic_ui.dart';
import '../widgets/standard_shell_header.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _service = GalleryService();
  GalleryFolder? _openFolder;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      body: Column(
        children: [
          StandardShellHeader(
            title: _openFolder?.label ?? 'Gallery',
            padding: const EdgeInsets.fromLTRB(4, 18, 16, 14),
            onBack: _openFolder == null
                ? null
                : () => setState(() => _openFolder = null),
          ),
          Expanded(
            child: ContentColumn(
              maxWidth: ResponsiveLayout.contentMaxWidth,
              child: StreamBuilder<List<GalleryImageModel>>(
              stream: _service.streamActive(),
              builder: (context, snap) {
                final list = snap.data ?? const <GalleryImageModel>[];

                if (snap.connectionState == ConnectionState.waiting &&
                    list.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: c.accentGold),
                  );
                }

                if (list.isEmpty) {
                  return _openFolder == null
                      ? _FolderGrid(
                          grouped: _dummyGrouped(),
                          onOpenFolder: (f) => setState(() => _openFolder = f),
                          isFallback: true,
                        )
                      : Center(
                          child: Text(
                            'No images in this folder yet',
                            style: AppTheme.lato(color: c.textMuted),
                          ),
                        );
                }

                if (_openFolder != null) {
                  final images = GalleryService.imagesInFolder(
                    list,
                    _openFolder!,
                  );
                  if (images.isEmpty) {
                    return Center(
                      child: Text(
                        'No images in this folder yet',
                        style: AppTheme.lato(color: c.textMuted),
                      ),
                    );
                  }
                  return _ImageGrid(
                    images: images,
                    onTap: (i) => _openViewer(context, images, i),
                  );
                }

                final grouped = GalleryService.groupByFolder(list);
                return _FolderGrid(
                  grouped: grouped,
                  onOpenFolder: (f) => setState(() => _openFolder = f),
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }

  Map<GalleryFolder, List<GalleryImageModel>> _dummyGrouped() {
    final urls = DummyData.galleryImages;
    final general = urls
        .asMap()
        .entries
        .map(
          (e) => GalleryImageModel(
            id: 'dummy_${e.key}',
            storagePath: '',
            downloadUrl: e.value,
            uploadedAt: DateTime.now(),
            isActive: true,
            folder: GalleryFolder.general.id,
          ),
        )
        .toList();
    return {GalleryFolder.general: general};
  }

  void _openViewer(
    BuildContext context,
    List<GalleryImageModel> images,
    int index,
  ) {
    final urls = images.map((e) => e.downloadUrl).toList();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _GalleryViewer(images: urls, initialIndex: index),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _FolderGrid extends StatelessWidget {
  const _FolderGrid({
    required this.grouped,
    required this.onOpenFolder,
    this.isFallback = false,
  });

  final Map<GalleryFolder, List<GalleryImageModel>> grouped;
  final ValueChanged<GalleryFolder> onOpenFolder;
  final bool isFallback;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final folders = GalleryFolder.visibleInGallery
        .where((f) => (grouped[f]?.isNotEmpty ?? false))
        .toList();

    if (folders.isEmpty) {
      return Center(
        child: Text('No albums yet', style: AppTheme.lato(color: c.textMuted)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (isFallback)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Showing sample images until Firebase albums load.',
              style: AppTheme.lato(fontSize: 12, color: c.textMuted),
            ),
          ),
        ...folders.map((folder) {
          final images = grouped[folder] ?? const <GalleryImageModel>[];
          final cover = images.isNotEmpty ? images.first.downloadUrl : '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FolderCard(
              folder: folder,
              count: images.length,
              coverUrl: cover,
              onTap: () => onOpenFolder(folder),
            ),
          );
        }),
      ],
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.count,
    required this.coverUrl,
    required this.onTap,
  });

  final GalleryFolder folder;
  final int count;
  final String coverUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GoldCard(
      backgroundColor: c.backgroundInput,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: SizedBox(
                width: 88,
                height: 88,
                child: coverUrl.isEmpty
                    ? ColoredBox(
                        color: c.backgroundElevated,
                        child: Icon(
                          Icons.folder_outlined,
                          color: c.accentGold,
                          size: 32,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const ShimmerPlaceholder(),
                        errorWidget: (context, url, error) => ColoredBox(
                          color: c.backgroundElevated,
                          child: Icon(
                            Icons.folder_outlined,
                            color: c.accentGold,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.label,
                      style: AppTheme.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count photo${count == 1 ? '' : 's'}',
                      style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded, color: c.accentGold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images, required this.onTap});

  final List<GalleryImageModel> images;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.gridColumns(context),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, i) {
        final url = images[i].downloadUrl;
        return InkWell(
          onTap: () => onTap(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  ShimmerPlaceholder(borderRadius: BorderRadius.circular(12)),
              errorWidget: (context, url, error) => const GoldPatternError(),
            ),
          ),
        );
      },
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
            loadingBuilder: (context, event) =>
                const Center(child: ShimmerPlaceholder()),
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
                        border: Border.all(color: c.borderDefault, width: 0.5),
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
                        border: Border.all(color: c.borderDefault, width: 0.5),
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
      final bytes = await _downloadImageToTemp(url);
      if (!mounted) return;
      if (bytes == null) return;
      await Share.shareXFiles([
        xFileFromBytes(
          bytes,
          name:
              'gallery_${DateTime.now().millisecondsSinceEpoch}.${_guessImageExt(url)}',
          mimeType: imageMimeTypeFromName(url),
        ),
      ]);
    } catch (_) {
      // Ignore; user can retry.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<Uint8List?> _downloadImageToTemp(String url) async {
    return downloadUrlBytes(url);
  }

  String _guessImageExt(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.png')) return 'png';
    if (lower.contains('.webp')) return 'webp';
    return 'jpg';
  }
}

const _closeSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M6 6l12 12M18 6L6 18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>';
