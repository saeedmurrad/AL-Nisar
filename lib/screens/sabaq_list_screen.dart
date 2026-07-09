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
import '../utils/firestore_error_messages.dart';
import '../utils/sabaq_order_utils.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/branded_state_view.dart';
import '../widgets/gold_card.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/shimmer_placeholder.dart';

class SabaqListScreen extends StatefulWidget {
  const SabaqListScreen({super.key});

  @override
  State<SabaqListScreen> createState() => _SabaqListScreenState();
}

class _SabaqListScreenState extends State<SabaqListScreen> {
  final _sabaq = SabaqService();
  final _access = SabaqAccessService();

  SabaqAccessRequestModel? _latestRequest(
    List<SabaqAccessRequestModel> all,
    String sabaqId,
  ) {
    final m = all.where((r) => r.sabaqId == sabaqId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return m.isEmpty ? null : m.first;
  }

  Widget _statusChip(AppThemeColors c, String label, {Color? color}) {
    final fg = color ?? c.accentGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fg.o(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.o(0.45)),
      ),
      child: Text(
        label,
        style: AppTheme.lato(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildAccessActions({
    required BuildContext context,
    required AuthProvider auth,
    required SabaqPdfModel s,
    required bool locked,
    required bool isNextRequestable,
    required SabaqAccessRequestModel? latest,
    required List<SabaqPdfModel> ordered,
    required Set<String> grantedIds,
  }) {
    final c = context.c;

    if (!locked) {
      return IconButton(
        onPressed: () => _openSabaq(
          context: context,
          auth: auth,
          s: s,
          ordered: ordered,
          grantedIds: grantedIds,
        ),
        icon: Icon(Icons.open_in_new, color: c.accentGold),
        tooltip: 'Open',
      );
    }

    final status = latest?.status.toLowerCase();

    // Only the next sequential Sabaq may be requested.
    if (!isNextRequestable) {
      return _statusChip(c, 'Locked', color: c.textMuted);
    }

    if (status == 'pending') {
      return _statusChip(c, 'Pending');
    }

    // Denied → allow send again (same next Sabaq).
    if (status == 'denied') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _statusChip(c, 'Denied', color: c.textMuted),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => _requestAccess(
              context: context,
              auth: auth,
              s: s,
              ordered: ordered,
              grantedIds: grantedIds,
              isResubmit: true,
            ),
            child: Text(
              'Send Request Again',
              style: AppTheme.lato(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: c.accentGold,
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'approved') {
      // Grant stream may lag briefly after approval.
      return _statusChip(c, 'Approved');
    }

    return TextButton(
      onPressed: () => _requestAccess(
        context: context,
        auth: auth,
        s: s,
        ordered: ordered,
        grantedIds: grantedIds,
      ),
      child: Text(
        'Send Access Request',
        style: AppTheme.lato(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: c.accentGold,
        ),
      ),
    );
  }

  List<SabaqPdfModel> _ordered(List<SabaqPdfModel> list) =>
      dedupeSabaqList(list);

  Future<void> _openSabaq({
    required BuildContext context,
    required AuthProvider auth,
    required SabaqPdfModel s,
    required List<SabaqPdfModel> ordered,
    required Set<String> grantedIds,
  }) async {
    final c = context.c;
    if (s.storagePath.trim().isEmpty) return;

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
      context.push(
        '/books/reader',
        extra: BookReaderArgs(book: book, autoDownloadIfMissing: true),
      );
      return;
    }

    final uid = auth.user?.uid;
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please sign in to open Sabaq',
            style: AppTheme.lato(color: c.textPrimary),
          ),
          backgroundColor: c.backgroundElevated,
        ),
      );
      return;
    }

    final unlocked = memberHasSabaqAccess(
      ordered: ordered,
      grantedIds: grantedIds,
      sabaqId: s.id,
    );

    if (unlocked) {
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
      context.push(
        '/books/reader',
        extra: BookReaderArgs(book: book, autoDownloadIfMissing: true),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This Sabaq is locked. Request access for the next available lesson.',
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
    required List<SabaqPdfModel> ordered,
    required Set<String> grantedIds,
    bool isResubmit = false,
  }) async {
    final c = context.c;
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please sign in to request access',
            style: AppTheme.lato(color: c.textPrimary),
          ),
          backgroundColor: c.backgroundElevated,
        ),
      );
      return;
    }

    final nextId = nextRequestableSabaqId(
      ordered: ordered,
      grantedIds: grantedIds,
    );
    if (nextId == null || nextId != s.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can only request the next Sabaq in sequence.',
            style: AppTheme.lato(color: c.textPrimary),
          ),
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
            isResubmit ? 'Request Sabaq access again' : 'Request Sabaq access',
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
        orderedSabaqs: ordered,
        grantedIds: grantedIds,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Access request sent',
            style: AppTheme.lato(color: c.textPrimary),
          ),
          backgroundColor: c.backgroundElevated,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = sabaqAccessRequestErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: AppTheme.lato(color: c.textPrimary)),
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
          const StandardShellHeader(
            title: 'Sabaq',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 14),
          ),
          Expanded(
            child: StreamBuilder<List<SabaqPdfModel>>(
              stream: _sabaq.streamSabaqPdfs(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const BrandedStateView(
                    icon: Icons.menu_book_outlined,
                    title: 'Loading',
                    message: 'Preparing lessons…',
                    loading: true,
                  );
                }

                final list = snap.data;
                final use = (list == null || list.isEmpty)
                    ? DummyData.sabaqList
                          .map(
                            (s) => SabaqPdfModel(
                              id: s.id,
                              titleEn: s.title,
                              titleUr: s.urduTitle ?? '',
                              storagePath: '',
                              thumbnailUrl: s.coverImageUrl,
                              uploadedAt: DateTime.now(),
                              isActive: true,
                              orderNumber: s.lessonNumber,
                            ),
                          )
                          .toList()
                    : list;

                final ordered = _ordered(use);
                final uid = auth.user?.uid ?? '';

                if (auth.isAdminOrHigher) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    itemCount: ordered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = ordered[i];
                      return InkWell(
                        onTap: () => _openSabaq(
                          context: context,
                          auth: auth,
                          s: s,
                          ordered: ordered,
                          grantedIds: const {},
                        ),
                        child: _SabaqPdfTile(s: s, locked: false),
                      );
                    },
                  );
                }

                return StreamBuilder<Set<String>>(
                  stream: uid.isEmpty
                      ? Stream.value(const <String>{})
                      : _access.streamGrantedSabaqIds(uid),
                  builder: (context, grantSnap) {
                    final grantedIds = grantSnap.data ?? const <String>{};
                    final nextId = uid.isEmpty
                        ? null
                        : nextRequestableSabaqId(
                            ordered: ordered,
                            grantedIds: grantedIds,
                          );

                    return StreamBuilder<List<SabaqAccessRequestModel>>(
                      stream: uid.isEmpty
                          ? Stream.value(const [])
                          : _access.streamRequestsForUser(uid),
                      builder: (context, reqSnap) {
                        final userRequests = reqSnap.data ?? [];
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          itemCount: ordered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final s = ordered[i];
                            final unlocked =
                                uid.isNotEmpty &&
                                memberHasSabaqAccess(
                                  ordered: ordered,
                                  grantedIds: grantedIds,
                                  sabaqId: s.id,
                                );
                            final locked = !unlocked;
                            final isNext = nextId != null && nextId == s.id;
                            final latest = _latestRequest(userRequests, s.id);

                            if (!locked) {
                              return InkWell(
                                onTap: () => _openSabaq(
                                  context: context,
                                  auth: auth,
                                  s: s,
                                  ordered: ordered,
                                  grantedIds: grantedIds,
                                ),
                                child: _SabaqPdfTile(s: s, locked: false),
                              );
                            }

                            return GoldCard(
                              backgroundColor: c.backgroundSurface,
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Opacity(
                                      opacity: 0.55,
                                      child: _SabaqPdfTile(
                                        s: s,
                                        locked: true,
                                        showChevron: false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildAccessActions(
                                    context: context,
                                    auth: auth,
                                    s: s,
                                    locked: locked,
                                    isNextRequestable: isNext,
                                    latest: latest,
                                    ordered: ordered,
                                    grantedIds: grantedIds,
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
                    errorWidget: (context, url, error) =>
                        const GoldPatternError(),
                  )
                : ColoredBox(
                    color: c.backgroundInput,
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: c.accentGold,
                    ),
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
            colorFilter: ColorFilter.mode(c.accentGold, BlendMode.srcIn),
          ),
      ],
    );
  }
}

const _chevronRightSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M9.5 5.5L16 12l-6.5 6.5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
