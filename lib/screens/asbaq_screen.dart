import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/dummy_data.dart';
import '../models/asbaq_pdf_model.dart';
import '../models/book_model.dart';
import '../models/book_reader_args.dart';
import '../services/asbaq_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/gold_card.dart';
import '../widgets/shimmer_placeholder.dart';

class AsbaqScreen extends StatelessWidget {
  const AsbaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final service = AsbaqService();

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: c.backgroundSurface,
            padding: const EdgeInsets.fromLTRB(10, 18, 16, 14),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => context.go('/home'),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: c.backgroundElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: c.borderDefault,
                              width: 0.5,
                            ),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asbaq-e-Tareeqat',
                              style: AppTheme.cormorantGaramond(
                                fontSize: 20,
                                letterSpacing: 0.8,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                'اسباقِ طریقت',
                                style: AppTheme.amiriUrdu(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Select an Asbaq PDF to begin',
                              style: TextStyle(
                                color: c.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AsbaqPdfModel>>(
              stream: service.streamAsbaqPdfs(),
              builder: (context, snap) {
                final list = snap.data;
                final use = (list == null || list.isEmpty) ? null : list;
                final fallback = DummyData.asbaqList
                    .map(
                      (s) => AsbaqPdfModel(
                        id: s.id,
                        titleEn: s.title,
                        titleUr: s.urduTitle ?? '',
                        storagePath: '',
                        thumbnailUrl: s.coverImageUrl,
                        uploadedAt: DateTime.now(),
                        isActive: true,
                      ),
                    )
                    .toList();

                final items = use ?? fallback;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    ...items.map((b) {
                      final asBook = BookModel(
                        id: b.id,
                        title: b.titleEn,
                        titleUrdu: b.titleUr,
                        author: '',
                        category: 'Asbaq-e-Tareeqat',
                        description: '',
                        storagePath: b.storagePath,
                        coverImageUrl: b.thumbnailUrl,
                        totalPages: 0,
                        uploadedAt: b.uploadedAt,
                        isActive: true,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            // If storagePath is empty (dummy), do nothing.
                            if (b.storagePath.trim().isEmpty) return;
                            context.push(
                              '/books/reader',
                              extra: BookReaderArgs(book: asBook, autoDownloadIfMissing: true),
                            );
                          },
                          child: _AsbaqPdfCard(
                            titleEn: b.titleEn,
                            titleUr: b.titleUr,
                            thumbUrl: b.thumbnailUrl,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

class _AsbaqPdfCard extends StatelessWidget {
  const _AsbaqPdfCard({
    required this.titleEn,
    required this.titleUr,
    required this.thumbUrl,
  });

  final String titleEn;
  final String titleUr;
  final String thumbUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasCover = thumbUrl.trim().isNotEmpty;
    return GoldCard(
      backgroundColor: c.backgroundSurface,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 70,
              height: 90,
              child: hasCover
                  ? CachedNetworkImage(
                      imageUrl: thumbUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => ShimmerPlaceholder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorWidget: (context, url, error) => const GoldPatternError(),
                    )
                  : ColoredBox(
                      color: c.backgroundInput,
                      child: Icon(Icons.picture_as_pdf_outlined, color: c.accentGold, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASBAQ PDF',
                  style: TextStyle(
                    color: c.accentGold,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titleEn,
                  style: AppTheme.cormorantGaramond(
                    fontSize: 17,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (titleUr.trim().isNotEmpty)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      titleUr,
                      style: AppTheme.amiriUrdu(
                        fontSize: 14,
                        height: 1.35,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'PDF',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
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
      ),
    );
  }
}

const _backSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M14.5 5.5L8 12l6.5 6.5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
const _chevronRightSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M9.5 5.5L16 12l-6.5 6.5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
