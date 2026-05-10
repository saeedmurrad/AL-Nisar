import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../data/dummy_data.dart';
import '../models/book_model.dart';
import '../models/book_reader_args.dart';
import '../models/sabaq_pdf_model.dart';
import '../services/sabaq_access_service.dart';
import '../services/sabaq_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/gold_card.dart';
import '../widgets/shimmer_placeholder.dart';

class SabaqListScreen extends StatefulWidget {
  const SabaqListScreen({super.key});

  @override
  State<SabaqListScreen> createState() => _SabaqListScreenState();
}

class _SabaqListScreenState extends State<SabaqListScreen> {
  final _sabaq = SabaqService();
  final _access = SabaqAccessService();

  List<SabaqPdfModel> _ordered(List<SabaqPdfModel> list) {
    final copy = [...list];
    copy.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
    return copy;
  }

  Future<void> _openSabaq({
    required BuildContext context,
    required AuthProvider auth,
    required SabaqPdfModel s,
    required String? freeSabaqId,
  }) async {
    final c = context.c;
    if (s.storagePath.trim().isEmpty) return;

    // Admins can open everything.
    if (auth.isAdminOrHigher) {
      final book = BookModel(
        id: s.id,
        title: s.titleEn,
        titleUrdu: s.titleUr,
        author: '',
        category: 'Sabaq',
        description: '',
        storagePath: s.storagePath,
        coverImageUrl: s.thumbnailUrl,
        totalPages: 0,
        uploadedAt: s.uploadedAt,
        isActive: true,
      );
      if (!context.mounted) return;
      context.push('/books/reader', extra: BookReaderArgs(book: book, autoDownloadIfMissing: true));
      return;
    }

    final uid = auth.user?.uid;
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to open Sabaq', style: AppTheme.lato(color: c.textPrimary)),
          backgroundColor: c.backgroundElevated,
        ),
      );
      return;
    }

    final isFree = freeSabaqId != null && freeSabaqId == s.id;

    final granted = await _access.hasAccess(uid, s.id);
    if (!context.mounted) return;

    if (isFree || granted) {
      final book = BookModel(
        id: s.id,
        title: s.titleEn,
        titleUrdu: s.titleUr,
        author: '',
        category: 'Sabaq',
        description: '',
        storagePath: s.storagePath,
        coverImageUrl: s.thumbnailUrl,
        totalPages: 0,
        uploadedAt: s.uploadedAt,
        isActive: true,
      );
      if (!context.mounted) return;
      context.push('/books/reader', extra: BookReaderArgs(book: book, autoDownloadIfMissing: true));
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This Sabaq is locked. Request access from Admin.',
          style: AppTheme.lato(color: c.textPrimary),
        ),
        backgroundColor: c.backgroundElevated,
      ),
    );
  }

  Future<void> _requestAccess({
    required BuildContext context,
    required AuthProvider auth,
    required SabaqPdfModel s,
  }) async {
    final c = context.c;
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to request access', style: AppTheme.lato(color: c.textPrimary)),
          backgroundColor: c.backgroundElevated,
        ),
      );
      return;
    }
    try {
      await _access.requestAccess(s);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access request sent', style: AppTheme.lato(color: c.textPrimary)),
          backgroundColor: c.backgroundElevated,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send request (rules/auth)', style: AppTheme.lato(color: c.textPrimary)),
          backgroundColor: c.backgroundElevated,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            title: 'Sabaq',
            onBack: () => context.go('/home'),
          ),
          Expanded(
            child: StreamBuilder<List<SabaqPdfModel>>(
              stream: _sabaq.streamSabaqPdfs(),
              builder: (context, snap) {
                final list = snap.data;
                final use = (list == null || list.isEmpty)
                    ? DummyData.sabaqList
                        .map(
                          (s) => SabaqPdfModel(
                            id: s.id,
                            titleEn: s.title,
                            titleUr: '',
                            storagePath: '',
                            thumbnailUrl: s.coverImageUrl,
                            uploadedAt: DateTime.now(),
                            isActive: true,
                          ),
                        )
                        .toList()
                    : list;

                final ordered = _ordered(use);
                final firstId = ordered.isNotEmpty ? ordered.first.id : null;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  itemCount: ordered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = ordered[i];
                    final uid = auth.user?.uid ?? '';

                    final isFree = !auth.isAdminOrHigher &&
                        firstId != null &&
                        firstId == s.id &&
                        uid.isNotEmpty;

                    if (auth.isAdminOrHigher || isFree) {
                      return InkWell(
                        onTap: () => _openSabaq(
                          context: context,
                          auth: auth,
                          s: s,
                          freeSabaqId: firstId,
                        ),
                        child: _SabaqPdfTile(s: s, locked: false),
                      );
                    }

                    return StreamBuilder<bool>(
                      stream: uid.isEmpty
                          ? Stream.value(false)
                          : _access.streamHasAccess(uid, s.id),
                      builder: (context, accSnap) {
                        final granted = accSnap.data == true;
                        final locked = !granted;
                        return GoldCard(
                          backgroundColor: c.backgroundSurface,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Opacity(
                                  opacity: locked ? 0.55 : 1,
                                  child: _SabaqPdfTile(s: s, locked: locked, showChevron: false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  if (locked)
                                    TextButton(
                                      onPressed: s.storagePath.trim().isEmpty
                                          ? null
                                          : () => _requestAccess(context: context, auth: auth, s: s),
                                      child: Text(
                                        'Request',
                                        style: AppTheme.lato(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: c.accentGold,
                                        ),
                                      ),
                                    ),
                                  if (!locked)
                                    IconButton(
                                      onPressed: () => _openSabaq(
                                        context: context,
                                        auth: auth,
                                        s: s,
                                        freeSabaqId: firstId,
                                      ),
                                      icon: Icon(Icons.open_in_new, color: c.accentGold),
                                      tooltip: 'Open',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}

class _SabaqPdfTile extends StatelessWidget {
  const _SabaqPdfTile({
    required this.s,
    required this.locked,
    this.showChevron = true,
  });

  final SabaqPdfModel s;
  final bool locked;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasThumb = s.thumbnailUrl.trim().isNotEmpty;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 80,
            child: hasThumb
                ? CachedNetworkImage(
                    imageUrl: s.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerPlaceholder(),
                    errorWidget: (context, url, error) => const GoldPatternError(),
                  )
                : ColoredBox(
                    color: c.backgroundInput,
                    child: Icon(Icons.picture_as_pdf_outlined, color: c.accentGold),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.titleEn,
                style: TextStyle(
                  color: locked ? c.textFaint : c.textPrimary,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
              if (s.titleUr.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    s.titleUr,
                    style: AppTheme.amiriUrdu(
                      fontSize: 13,
                      height: 1.35,
                      color: locked ? c.textFaint : c.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'PDF',
                style: TextStyle(
                  color: locked ? c.textFaint : c.textFaint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (showChevron)
          SvgPicture.string(
            _chevronRightSvg,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              c.accentGold,
              BlendMode.srcIn,
            ),
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: c.backgroundSurface,
      padding: const EdgeInsets.fromLTRB(10, 18, 16, 14),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.backgroundElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.borderDefault, width: 0.5),
                ),
                child: SvgPicture.string(
                  _backSvg,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    c.accentGold,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTheme.cinzelHeading(fontSize: 18, letterSpacing: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}

const _backSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M14.5 5.5L8 12l6.5 6.5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
const _chevronRightSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M9.5 5.5L16 12l-6.5 6.5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

