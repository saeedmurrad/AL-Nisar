import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../data/dummy_data.dart';
import '../models/book_model.dart';
import '../models/book_reader_args.dart';
import '../models/sabaq_access_request_model.dart';
import '../models/sabaq_pdf_model.dart';
import '../services/sabaq_access_service.dart';
import '../services/sabaq_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/app_drawer.dart';
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

  SabaqAccessRequestModel? _latestRequest(List<SabaqAccessRequestModel> all, String sabaqId) {
    final m = all.where((r) => r.sabaqId == sabaqId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return m.isEmpty ? null : m.first;
  }

  String _statusLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'denied':
        return 'Denied';
      default:
        return raw;
    }
  }

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
    final msgCtrl = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cc = ctx.c;
        return AlertDialog(
          backgroundColor: cc.backgroundSurface,
          title: Text(
            'Request Sabaq access',
            style: AppTheme.cormorantGaramond(color: cc.textPrimary),
          ),
          content: TextField(
            controller: msgCtrl,
            maxLines: 4,
            maxLength: 500,
            style: AppTheme.lato(color: cc.textPrimary),
            decoration: InputDecoration(
              hintText: 'Optional message to admin…',
              hintStyle: AppTheme.lato(color: cc.textFaint),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: AppTheme.lato(color: cc.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Send', style: AppTheme.lato(color: cc.accentGold)),
            ),
          ],
        );
      },
    );
    if (send != true) return;

    final displayName = auth.profile?.displayName.trim().isNotEmpty == true
        ? auth.profile!.displayName.trim()
        : (auth.user?.displayName ?? '');
    try {
      await _access.requestAccess(
        s,
        message: msgCtrl.text,
        displayName: displayName,
      );
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
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const _TopBar(title: 'Sabaq'),
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
                final uid = auth.user?.uid ?? '';

                return StreamBuilder<List<SabaqAccessRequestModel>>(
                  stream: uid.isEmpty ? Stream.value(const []) : _access.streamRequestsForUser(uid),
                  builder: (context, reqSnap) {
                    final userRequests = reqSnap.data ?? [];
                    return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  itemCount: ordered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = ordered[i];

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
                        final latest = _latestRequest(userRequests, s.id);
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
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (latest != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        _statusLabel(latest.status),
                                        style: AppTheme.lato(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: c.accentGold,
                                        ),
                                      ),
                                    ),
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
                );
              },
            ),
          ),
        ],
      ),
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
  const _TopBar({required this.title});

  final String title;

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
            const DrawerMenuButton(),
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

const _chevronRightSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M9.5 5.5L16 12l-6.5 6.5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

