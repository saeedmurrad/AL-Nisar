import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../data/dummy_data.dart';
import '../models/news_firestore_model.dart';
import '../services/news_events_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../navigation/go_router_helpers.dart';
import '../widgets/news_cover_image.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({
    super.key,
    required this.newsId,
    this.initial,
  });

  final String newsId;
  final NewsFirestoreModel? initial;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fallback = DummyData.newsById(newsId) ?? DummyData.newsFeatured;
    final seed = initial;

    return FutureBuilder<NewsFirestoreModel?>(
      future: NewsEventsService().getNewsById(newsId),
      initialData: seed,
      builder: (context, snap) {
        final doc = snap.data ?? seed;
        final title = doc?.title.isNotEmpty == true ? doc!.title : fallback.title;
        final category =
            doc?.category.isNotEmpty == true ? doc!.category : fallback.category;
        final dateLabel =
            doc?.dateLabel.isNotEmpty == true ? doc!.dateLabel : fallback.dateLabel;
        final imageUrl =
            doc?.imageUrl.isNotEmpty == true ? doc!.imageUrl : fallback.imageUrl;
        final paragraphs = (doc?.bodyParagraphs.isNotEmpty == true)
            ? doc!.bodyParagraphs
            : (fallback.bodyParagraphs.isNotEmpty
                ? fallback.bodyParagraphs
                : [
                    'This is placeholder body text for the article.',
                    'It will be replaced when content is available.',
                    'May your reading be blessed and calm.',
                  ]);

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NewsCoverImage(imageUrl: imageUrl, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            c.backgroundPrimary.o(0.05),
                            c.backgroundPrimary.o(0.55),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 16, 0),
                          child: InkWell(
                            onTap: () => popOrGoHome(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: c.backgroundElevated.o(0.82),
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: c.accentGold.o(0.22),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: c.accentGold.o(0.45)),
                          ),
                          child: Text(
                            category,
                            style: AppTheme.lato(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: c.accentGold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateLabel,
                          style: AppTheme.lato(
                            fontSize: 12,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: AppTheme.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final p in paragraphs) ...[
                      Text(
                        p,
                        style: AppTheme.lato(
                          fontSize: 15,
                          height: 1.65,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          final body = paragraphs.join('\n\n');
                          Share.share('$title\n\n$body');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.accentGold,
                          side: BorderSide(color: c.accentGold, width: 1.1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_outlined, color: c.accentGold),
                            const SizedBox(width: 8),
                            Text(
                              'Share',
                              style: AppTheme.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: c.accentGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const _backSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M14.5 5.5L8 12l6.5 6.5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
