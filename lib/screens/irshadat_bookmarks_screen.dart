import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../models/irshad_firestore_model.dart';
import '../models/irshadat_bookmark_model.dart';
import '../services/irshadat_bookmark_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/gold_card.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/shimmer_placeholder.dart';

class IrshadatBookmarksScreen extends StatefulWidget {
  const IrshadatBookmarksScreen({super.key});

  @override
  State<IrshadatBookmarksScreen> createState() => _IrshadatBookmarksScreenState();
}

class _IrshadatBookmarksScreenState extends State<IrshadatBookmarksScreen> {
  final _service = IrshadatBookmarkService();
  Future<List<IrshadatBookmarkModel>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _service.getAllBookmarks();
    });
  }

  Future<void> _confirmDelete(IrshadatBookmarkModel bm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.c;
        return AlertDialog(
          backgroundColor: c.backgroundSurface,
          title: Text(
            'Remove bookmark?',
            style: AppTheme.cormorantGaramond(color: c.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: AppTheme.lato(color: c.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Remove', style: AppTheme.lato(color: c.accentGold)),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await _service.remove(bm.language, bm.irshadId);
      _reload();
    }
  }

  Future<void> _share(IrshadatBookmarkModel bm) async {
    final url = bm.imageUrl.trim();
    final msg = [
      'Irshad (${bm.language.label}) — ${bm.dateLabel}',
      if (bm.text.trim().isNotEmpty) bm.text.trim(),
      'AL Nisar App',
    ].join('\n\n');

    if (url.isEmpty) {
      await Share.share(msg);
      return;
    }

    try {
      final f = await _downloadToTemp(url, 'irshad_saved_${bm.id}');
      if (f == null) {
        await Share.share('$msg\n\n$url');
        return;
      }
      await Share.shareXFiles([XFile(f.path)], text: msg);
    } catch (_) {
      await Share.share('$msg\n\n$url');
    }
  }

  Future<File?> _downloadToTemp(String url, String baseName) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final dir = await getTemporaryDirectory();
    final ext = _guessImageExt(uri.path);
    final out = File('${dir.path}/$baseName.$ext');

    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final bytes = await consolidateHttpClientResponseBytes(res);
      await out.writeAsBytes(bytes, flush: true);
      return out;
    } finally {
      client.close(force: true);
    }
  }

  String _guessImageExt(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  void _open(IrshadatBookmarkModel bm) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final c = ctx.c;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: 16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bm.dateLabel,
                      style: AppTheme.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.accentGold.o(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.accentGold.o(0.45)),
                    ),
                    child: Text(
                      bm.language.label,
                      style: AppTheme.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (bm.imageUrl.trim().isNotEmpty) ...[
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: bm.imageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      placeholder: (context, url) => const ShimmerPlaceholder(),
                      errorWidget: (context, url, error) => Container(
                        color: c.backgroundInput,
                        child: Center(
                          child: Text(
                            'Image failed to load',
                            style: AppTheme.lato(color: c.textMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Flexible(
                child: SingleChildScrollView(
                  child: bm.language.isRtl
                      ? Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            bm.text,
                            style: AppTheme.amiriUrdu(
                              fontSize: 18,
                              height: 2.0,
                              color: c.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Text(
                          bm.text,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 15,
                            height: 1.7,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _share(bm);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.accentGold,
                        side: BorderSide(color: c.accentGold.o(0.65)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Share', style: AppTheme.lato(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _confirmDelete(bm);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accentGold,
                        foregroundColor: Theme.of(ctx).brightness == Brightness.dark
                            ? c.backgroundPrimary
                            : c.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text('Remove', style: AppTheme.lato(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StandardShellHeader(
            padding: const EdgeInsets.fromLTRB(4, 12, 16, 14),
            titleWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Irshadat',
                  style: AppTheme.cormorantGaramond(
                    fontSize: 22,
                    color: c.textPrimary,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    'محفوظ ارشادات',
                    style: AppTheme.amiriUrdu(
                      fontSize: 15,
                      height: 1.3,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            trailing: FutureBuilder<List<IrshadatBookmarkModel>>(
              future: _future,
              builder: (context, snap) {
                final n = snap.data?.length ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.accentGold.o(0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: c.accentGold.o(0.5)),
                  ),
                  child: Text(
                    '$n saved',
                    style: AppTheme.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<IrshadatBookmarkModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: c.accentGold),
                  );
                }
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border, size: 72, color: c.accentGold),
                          const SizedBox(height: 20),
                          Text(
                            'No saved Irshadat yet',
                            style: AppTheme.cormorantGaramond(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap Bookmark on an Irshad to save it here',
                            textAlign: TextAlign.center,
                            style: AppTheme.lato(fontSize: 14, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final bm = list[i];
                    return InkWell(
                      onTap: () => _open(bm),
                      onLongPress: () => _confirmDelete(bm),
                      borderRadius: BorderRadius.circular(14),
                      child: GoldCard(
                        backgroundColor: c.backgroundSurface,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bm.imageUrl.trim().isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: bm.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                  placeholder: (context, url) => Container(
                                    width: 70,
                                    height: 70,
                                    color: c.backgroundInput,
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 70,
                                    height: 70,
                                    color: c.backgroundInput,
                                    child: Icon(Icons.image_not_supported_outlined,
                                        color: c.textMuted),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: c.backgroundInput,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: c.borderDefault, width: 0.5),
                                ),
                                child: Icon(Icons.format_quote, color: c.accentGold),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bm.dateLabel.isEmpty ? 'Irshad' : bm.dateLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.lato(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: c.backgroundElevated,
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: c.borderDefault, width: 0.5),
                                        ),
                                        child: Text(
                                          bm.language.label,
                                          style: AppTheme.lato(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: c.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    bm.text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: bm.language == IrshadatLanguage.urdu
                                        ? AppTheme.amiriUrdu(
                                            fontSize: 14,
                                            height: 1.6,
                                            color: c.textSecondary,
                                          )
                                        : AppTheme.lato(
                                            fontSize: 12,
                                            color: c.textMuted,
                                            height: 1.4,
                                          ).copyWith(fontStyle: FontStyle.italic),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(bm.savedAt),
                                    style: AppTheme.lato(fontSize: 10, color: c.textFaint),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

