import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../data/dummy_data.dart';
import '../models/irshad_firestore_model.dart';
import '../services/irshadat_bookmark_service.dart';
import '../services/irshadat_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/gold_card.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/ornament_divider.dart';
import '../widgets/shimmer_placeholder.dart';

class IrshadatScreen extends StatefulWidget {
  const IrshadatScreen({super.key});

  @override
  State<IrshadatScreen> createState() => _IrshadatScreenState();
}

class _IrshadatScreenState extends State<IrshadatScreen> {
  IrshadatLanguage _language = IrshadatLanguage.urdu;
  final _service = IrshadatService();
  final _bookmarkService = IrshadatBookmarkService();
  final _searchCtrl = TextEditingController();
  Set<String> _bookmarkedKeys = {};

  String _bookmarkKey(IrshadFirestoreModel ir) => '${_language.name}_${ir.id}';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final list = await _bookmarkService.getAllBookmarks();
    final keys = list.map((b) => b.id).toSet();
    if (!mounted) return;
    setState(() => _bookmarkedKeys = keys);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark(IrshadFirestoreModel ir) async {
    final key = _bookmarkKey(ir);
    final isSaved = _bookmarkedKeys.contains(key);
    setState(() {
      if (isSaved) {
        _bookmarkedKeys.remove(key);
      } else {
        _bookmarkedKeys.add(key);
      }
    });
    try {
      if (isSaved) {
        await _bookmarkService.remove(_language, ir.id);
      } else {
        await _bookmarkService.add(language: _language, item: ir);
      }
    } catch (_) {
      // Revert on failure.
      if (!mounted) return;
      setState(() {
        if (isSaved) {
          _bookmarkedKeys.add(key);
        } else {
          _bookmarkedKeys.remove(key);
        }
      });
    }
  }

  Future<void> _shareIrshad(IrshadFirestoreModel ir) async {
    final text = ir.text.trim();
    final url = ir.imageUrl.trim();
    final msg = [
      'Irshad (${_language.label}) — ${ir.dateLabel}',
      if (text.isNotEmpty) text,
      'AL Nisar App',
    ].join('\n\n');

    if (url.isEmpty) {
      await Share.share(msg);
      return;
    }

    try {
      final f = await _downloadToTemp(url, 'irshad_${ir.id}');
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

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      body: Column(
        children: [
          const StandardShellHeader(
            title: 'Irshadat',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 12),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _LanguageToggle(
                  urduSelected: _language == IrshadatLanguage.urdu,
                  onSelectUrdu: () => setState(() => _language = IrshadatLanguage.urdu),
                  onSelectEnglish: () => setState(() => _language = IrshadatLanguage.english),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<IrshadFirestoreModel>>(
              stream: _service.streamIrshadat(_language),
              builder: (context, snap) {
                final list = snap.data;
                final items = (list == null || list.isEmpty)
                    ? null
                    : list;

                // Fallback to dummy content when Firebase is empty/unavailable.
                final fallback = DummyData.irshadList
                    .map(
                      (d) => IrshadFirestoreModel(
                        id: d.dateLabel,
                        dateLabel: d.dateLabel,
                        text: _language == IrshadatLanguage.urdu ? d.urdu : d.english,
                        imageUrl: '',
                        createdAt: DateTime.now(),
                        isActive: true,
                      ),
                    )
                    .toList();

                final use = items ?? fallback;
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? use
                    : use.where((ir) {
                        final text = ir.text.toLowerCase();
                        final date = ir.dateLabel.toLowerCase();
                        return text.contains(q) || date.contains(q);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        q.isEmpty ? 'No Irshadat yet' : 'No matches for your search',
                        style: AppTheme.lato(color: c.textMuted, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final ir = filtered[i];
                    final bookmarked = _bookmarkedKeys.contains(_bookmarkKey(ir));
                    final hasText = ir.text.trim().isNotEmpty;
                    return GoldCard(
                      backgroundColor: c.backgroundInput,
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: ir.imageUrl.trim().isNotEmpty
                                        ? ir.imageUrl
                                        : DummyData.rosePetals,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                    placeholder: (context, url) =>
                                        const ShimmerPlaceholder(),
                                    errorWidget: (context, url, error) =>
                                        const GoldPatternError(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                ir.dateLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: c.textMuted,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const OrnamentDivider(),
                              if (hasText) ...[
                                const SizedBox(height: 14),
                                _language.isRtl
                                    ? Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(
                                          ir.text,
                                          textAlign: TextAlign.center,
                                          style: AppTheme.amiriUrdu(
                                            fontSize: 18,
                                            height: 2.1,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        ir.text,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: c.textSecondary,
                                          fontSize: 14,
                                          height: 1.7,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionPill(
                                      label: bookmarked ? 'Saved' : 'Bookmark',
                                      iconSvg:
                                          bookmarked ? _bookmarkFilledSvg : _bookmarkSvg,
                                      active: bookmarked,
                                      onTap: () => _toggleBookmark(ir),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _ActionPill(
                                      label: 'Share',
                                      iconSvg: _shareSvg,
                                      onTap: () => _shareIrshad(ir),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.backgroundInput,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderDefault, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SvgPicture.string(
            _searchSvg,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              c.accentGold,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: c.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search Irshadat…',
                hintStyle: TextStyle(
                  color: c.textFaint,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.urduSelected,
    required this.onSelectUrdu,
    required this.onSelectEnglish,
  });

  final bool urduSelected;
  final VoidCallback onSelectUrdu;
  final VoidCallback onSelectEnglish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TogglePill(
            label: 'Urdu',
            selected: urduSelected,
            onTap: onSelectUrdu,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TogglePill(
            label: 'English',
            selected: !urduSelected,
            onTap: onSelectEnglish,
          ),
        ),
      ],
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.backgroundElevated : c.backgroundInput,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? c.accentGold.o(0.55) : c.borderDefault,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? c.textPrimary : c.textMuted,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.iconSvg,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final String iconSvg;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? c.accentGold.o(0.18) : c.backgroundSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.borderDefault, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(
              iconSvg,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                active ? c.accentGold : c.accentGold,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? c.accentGold : c.textPrimary,
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _searchSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M10.5 18.5a8 8 0 1 1 0-16 8 8 0 0 1 0 16z" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M16.5 16.5L21 21" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>';
const _bookmarkSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M7 4h10v17l-5-3-5 3V4z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>';
const _bookmarkFilledSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M7 4h10v17l-5-3-5 3V4z" fill="currentColor" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/></svg>';
const _shareSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M16 7l-8 4 8 4" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/><path d="M18 9.2a2.2 2.2 0 1 0 0-4.4 2.2 2.2 0 0 0 0 4.4zM6 13.2a2.2 2.2 0 1 0 0-4.4 2.2 2.2 0 0 0 0 4.4zM18 19.2a2.2 2.2 0 1 0 0-4.4 2.2 2.2 0 0 0 0 4.4z" fill="none" stroke="currentColor" stroke-width="1.6"/></svg>';

