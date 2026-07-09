import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../data/dummy_data.dart';
import '../navigation/go_router_helpers.dart';
import '../models/lesson_model.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../utils/responsive_layout.dart';
import '../widgets/gold_card.dart';
import '../widgets/locked_sabaq_card.dart';
import '../widgets/shimmer_placeholder.dart';

class SabaqReaderScreen extends StatefulWidget {
  const SabaqReaderScreen({super.key, required this.lesson});

  final LessonModel lesson;

  @override
  State<SabaqReaderScreen> createState() => _SabaqReaderScreenState();
}

class _SabaqReaderScreenState extends State<SabaqReaderScreen> {
  final _pc = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lesson = widget.lesson;
    final pages = lesson.pages;
    final locked = DummyData.sabaqList.where((s) => s.isLocked).toList();

    return Scaffold(
      body: Column(
        children: [
          _TopBar(title: 'Sabaq Reader', onBack: () => popOrGoHome(context)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _HeaderBanner(
                  imageUrl: lesson.coverImageUrl,
                  title: lesson.title,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    children: [
                      GoldCard(
                        backgroundColor: c.backgroundSurface,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    pages[_index].chapterTitle,
                                    style: AppTheme.cinzelHeading(
                                      fontSize: 16,
                                      letterSpacing: 1.3,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Page ${_index + 1}/${pages.length}',
                                  style: TextStyle(
                                    color: c.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: ResponsiveLayout.lessonPageViewportHeight(
                                context,
                              ),
                              child: PageView.builder(
                                controller: _pc,
                                itemCount: pages.length,
                                onPageChanged: (i) =>
                                    setState(() => _index = i),
                                itemBuilder: (context, i) =>
                                    _PageContent(page: pages[i]),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _NavPill(
                                  label: 'Prev',
                                  enabled: _index > 0,
                                  onTap: () {
                                    if (_index == 0) return;
                                    _pc.previousPage(
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                ),
                                const Spacer(),
                                SmoothPageIndicator(
                                  controller: _pc,
                                  count: pages.length,
                                  effect: WormEffect(
                                    dotHeight: 7,
                                    dotWidth: 7,
                                    spacing: 8,
                                    dotColor: c.borderDefault.o(0.9),
                                    activeDotColor: c.accentGold,
                                  ),
                                ),
                                const Spacer(),
                                _NavPill(
                                  label: 'Next',
                                  enabled: _index < pages.length - 1,
                                  onTap: () {
                                    if (_index >= pages.length - 1) return;
                                    _pc.nextPage(
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionPill(
                              label: 'Bookmark',
                              iconSvg: _bookmarkSvg,
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionPill(
                              label: 'Share',
                              iconSvg: _shareSvg,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Locked Sabaq',
                          style: TextStyle(
                            color: c.textMuted.o(0.95),
                            letterSpacing: 1.8,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...locked
                          .take(3)
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LockedSabaqCard(
                                title: s.title,
                                subtitle: s.subtitle,
                                pageCount: s.pageCount,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

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
                  colorFilter: ColorFilter.mode(c.accentGold, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.cinzelHeading(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({required this.imageUrl, required this.title});

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: SizedBox(
        height: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ShimmerPlaceholder(),
              errorWidget: (context, url, error) => const GoldPatternError(),
            ),
            Container(color: c.backgroundPrimary.withValues(alpha: 0.55)),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.cinzelHeading(
                    fontSize: 18,
                    letterSpacing: 1.6,
                    color: c.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});

  final LessonPage page;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              page.urdu,
              style: AppTheme.amiriUrdu(
                fontSize: 17,
                color: c.textSecondary,
                height: 2.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: c.backgroundElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.borderDefault, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 96,
                  decoration: BoxDecoration(
                    color: c.accentGold.o(0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                    child: Text(
                      page.english,
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 13,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.backgroundElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.borderDefault, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? c.textPrimary : c.textFaint,
            fontSize: 12,
            letterSpacing: 0.8,
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
  });

  final String label;
  final String iconSvg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.backgroundSurface,
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
              colorFilter: ColorFilter.mode(c.accentGold, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _backSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M14.5 5.5L8 12l6.5 6.5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
const _bookmarkSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M7 4h10v17l-5-3-5 3V4z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>';
const _shareSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M16 7l-8 4 8 4" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/><path d="M18 9.2a2.2 2.2 0 1 0 0-4.4 2.2 2.2 0 0 0 0 4.4zM6 13.2a2.2 2.2 0 1 0 0-4.4 2.2 2.2 0 0 0 0 4.4zM18 19.2a2.2 2.2 0 1 0 0-4.4 2.2 2.2 0 0 0 0 4.4z" fill="none" stroke="currentColor" stroke-width="1.6"/></svg>';
