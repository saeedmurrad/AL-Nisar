import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/event_firestore_model.dart';
import '../models/news_firestore_model.dart';
import '../services/news_events_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../utils/event_date_labels.dart';
import '../widgets/news_cover_image.dart';
import '../widgets/branded_state_view.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/islamic_ui.dart';

class NewsEventsScreen extends StatefulWidget {
  const NewsEventsScreen({super.key});

  @override
  State<NewsEventsScreen> createState() => _NewsEventsScreenState();
}

class _NewsEventsScreenState extends State<NewsEventsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = NewsEventsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _onGold(BuildContext context, AppThemeColors c) {
    return Theme.of(context).brightness == Brightness.dark
        ? c.backgroundPrimary
        : c.textPrimary;
  }

  Widget _loadingState(AppThemeColors c) {
    return BrandedStateView(
      icon: Icons.article_outlined,
      title: 'Loading',
      message: 'Fetching latest updates…',
      loading: true,
    );
  }

  Widget _emptyState(AppThemeColors c, String label) {
    return BrandedStateView(
      icon: Icons.article_outlined,
      title: 'Nothing here yet',
      message: label,
    );
  }

  Widget _errorState(AppThemeColors c, String label) {
    return BrandedStateView(
      icon: Icons.wifi_off_rounded,
      title: 'Could not load',
      message: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final onGold = _onGold(context, c);

    return Scaffold(
      body: Column(
        children: [
          StandardShellHeader(
            padding: const EdgeInsets.fromLTRB(4, 18, 16, 10),
            titleWidget: Text(
              'News & Events',
              style: AppTheme.cormorantGaramond(
                fontSize: 20,
                letterSpacing: 0.5,
                color: kOnEmeraldColors.textPrimary,
              ),
            ),
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Cap the tab pills so they stay compact on wide screens.
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PillTabButton(
                            label: 'News',
                            urdu: 'خبریں',
                            selected: _tabController.index == 0,
                            onTap: () => _tabController.animateTo(0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PillTabButton(
                            label: 'Events',
                            urdu: 'تقریبات',
                            selected: _tabController.index == 1,
                            onTap: () => _tabController.animateTo(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StreamBuilder<List<NewsFirestoreModel>>(
                  stream: _service.streamNews(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        snap.data == null) {
                      return _loadingState(c);
                    }
                    if (snap.hasError) {
                      return _errorState(
                        c,
                        'Could not load news. Check your connection and try again.',
                      );
                    }

                    final use = snap.data ?? const <NewsFirestoreModel>[];

                    if (use.isEmpty) {
                      return _emptyState(c, 'No news articles yet.');
                    }

                    final featured = use.first;
                    final rest = use.length <= 1
                        ? <NewsFirestoreModel>[]
                        : use.sublist(1);

                    return _NewsTabFirestore(
                      featured: featured,
                      items: rest,
                      onGold: onGold,
                    );
                  },
                ),
                StreamBuilder<List<EventFirestoreModel>>(
                  stream: _service.streamEvents(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        snap.data == null) {
                      return _loadingState(c);
                    }
                    if (snap.hasError) {
                      return _errorState(
                        c,
                        'Could not load events. Check your connection and try again.',
                      );
                    }

                    final use = snap.data ?? const <EventFirestoreModel>[];

                    if (use.isEmpty) {
                      return _emptyState(c, 'No events scheduled yet.');
                    }

                    return _EventsTabFirestore(events: use);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTabButton extends StatelessWidget {
  const _PillTabButton({
    required this.label,
    required this.urdu,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String urdu;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // These pills sit on the emerald header band: gold fill with deep
    // emerald text when selected reads crisply in both themes.
    final onGold = kDeepEmerald;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? c.accentGold : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? c.accentGold : c.accentGold.o(0.55),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTheme.lato(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? onGold : c.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                urdu,
                style: AppTheme.amiriUrdu(
                  fontSize: 12,
                  height: 1.2,
                  color: selected ? onGold.o(0.92) : c.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small gold uppercase section label with an optional count chip.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.sectionCaption(
              color: c.accentGold,
              fontSize: 12,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: c.borderFaint)),
          if (count != null) ...[
            const SizedBox(width: 10),
            Text(
              '$count',
              style: AppTheme.lato(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NewsTabFirestore extends StatelessWidget {
  const _NewsTabFirestore({
    required this.featured,
    required this.items,
    required this.onGold,
  });

  final NewsFirestoreModel featured;
  final List<NewsFirestoreModel> items;
  final Color onGold;

  static String _publishedLabel(NewsFirestoreModel n) =>
      n.dateLabel.trim().isNotEmpty
      ? n.dateLabel
      : EventDateLabels.newsDateLabel(n.createdAt);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Featured story — large image with overlaid meta.
            _FeaturedNewsCard(
              news: featured,
              publishedLabel: _publishedLabel(featured),
              onGold: onGold,
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 22),
              _SectionLabel(label: 'More Stories', count: items.length),
              ...items.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NewsRowCard(
                    news: n,
                    publishedLabel: _publishedLabel(n),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeaturedNewsCard extends StatelessWidget {
  const _FeaturedNewsCard({
    required this.news,
    required this.publishedLabel,
    required this.onGold,
  });

  final NewsFirestoreModel news;
  final String publishedLabel;
  final Color onGold;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.backgroundSurface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/news-events/news-detail', extra: news),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                NewsCoverImage(
                  imageUrl: news.imageUrl,
                  height: 210,
                  width: double.infinity,
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: _Pill(
                    text: news.category.isEmpty ? 'NEWS' : news.category,
                    bg: c.accentGold,
                    fg: onGold,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: AppTheme.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MetaRow(
                    icon: Icons.calendar_today_rounded,
                    text: 'Published · $publishedLabel',
                    trailing: news.readTime,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsRowCard extends StatelessWidget {
  const _NewsRowCard({required this.news, required this.publishedLabel});

  final NewsFirestoreModel news;
  final String publishedLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.backgroundSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/news-events/news-detail', extra: news),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NewsCoverImage(
                imageUrl: news.imageUrl,
                width: 84,
                height: 84,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (news.category.trim().isNotEmpty)
                      Text(
                        news.category.toUpperCase(),
                        style: AppTheme.sectionCaption(
                          color: c.accentGold,
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.cormorantGaramond(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: c.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '$publishedLabel · ${news.readTime}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.lato(
                              fontSize: 11.5,
                              color: c.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsTabFirestore extends StatelessWidget {
  const _EventsTabFirestore({required this.events});

  final List<EventFirestoreModel> events;

  @override
  Widget build(BuildContext context) {
    // Split by the event's real date and order each group sensibly.
    final upcoming = events.where((e) => !e.isPast).toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    final past = events.where((e) => e.isPast).toList()
      ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

    final children = <Widget>[];

    if (upcoming.isNotEmpty) {
      final next = upcoming.first;
      children.add(_NextEventHero(event: next));
      final rest = upcoming.skip(1).toList();
      if (rest.isNotEmpty) {
        children
          ..add(const SizedBox(height: 22))
          ..add(_SectionLabel(label: 'Upcoming', count: rest.length));
        for (final e in rest) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventRowCard(event: e, past: false),
            ),
          );
        }
      }
    } else {
      children.add(const _NoUpcomingBanner());
    }

    if (past.isNotEmpty) {
      children
        ..add(const SizedBox(height: 22))
        ..add(_SectionLabel(label: 'Past Events', count: past.length));
      for (final e in past) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EventRowCard(event: e, past: true),
          ),
        );
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: children,
        ),
      ),
    );
  }
}

/// Prominent card for the soonest upcoming event.
class _NextEventHero extends StatelessWidget {
  const _NextEventHero({required this.event});

  final EventFirestoreModel event;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = event.isToday ? 'HAPPENING TODAY' : 'NEXT EVENT';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/news-events/event-detail', extra: event),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(c.accentGold.o(0.14), c.backgroundSurface),
                c.backgroundSurface,
              ],
            ),
            border: Border.all(color: c.accentGold.o(0.4), width: 1),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CalendarTile(
                    day: event.day,
                    month: event.monthAbbr,
                    past: false,
                    large: true,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Pill(
                          text: label,
                          bg: c.accentGold,
                          fg: isDark ? kDeepEmerald : Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.cormorantGaramond(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: c.textPrimary,
                          ),
                        ),
                        if (event.urduTitle.trim().isNotEmpty)
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              event.urduTitle,
                              style: AppTheme.amiriUrdu(
                                fontSize: 14,
                                height: 1.4,
                                color: c.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MetaRow(
                icon: Icons.calendar_today_rounded,
                text: event.fullDateLine,
              ),
              const SizedBox(height: 8),
              _MetaRow(icon: Icons.schedule_rounded, text: event.timeLabel),
              const SizedBox(height: 8),
              _MetaRow(
                icon: Icons.location_on_rounded,
                text: event.location,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push(
                    '/news-events/event-detail',
                    extra: event,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accentGold,
                    foregroundColor: isDark ? kDeepEmerald : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: AppTheme.lato(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: isDark ? kDeepEmerald : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventRowCard extends StatelessWidget {
  const _EventRowCard({required this.event, required this.past});

  final EventFirestoreModel event;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: past ? c.backgroundElevated.o(0.5) : c.backgroundSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/news-events/event-detail', extra: event),
        child: Opacity(
          opacity: past ? 0.72 : 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalendarTile(
                  day: event.day,
                  month: event.monthAbbr,
                  past: past,
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
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.cormorantGaramond(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                          if (past) ...[
                            const SizedBox(width: 8),
                            _Pill(
                              text: 'ENDED',
                              bg: c.textMuted.o(0.16),
                              fg: c.textMuted,
                            ),
                          ],
                        ],
                      ),
                      if (event.urduTitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            event.urduTitle,
                            style: AppTheme.amiriUrdu(
                              fontSize: 13,
                              height: 1.3,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      _MetaRow(
                        icon: Icons.location_on_rounded,
                        text: event.location,
                        small: true,
                      ),
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: Icons.schedule_rounded,
                        text: event.timeLabel,
                        small: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded day/month calendar tile — gold for upcoming, muted for past.
class _CalendarTile extends StatelessWidget {
  const _CalendarTile({
    required this.day,
    required this.month,
    required this.past,
    this.large = false,
  });

  final int day;
  final String month;
  final bool past;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final accent = past ? c.textMuted : c.accentGold;
    final size = large ? 68.0 : 58.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.o(past ? 0.10 : 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.o(0.35), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: AppTheme.cormorantGaramond(
              fontSize: large ? 28 : 24,
              fontWeight: FontWeight.w700,
              height: 1,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            month,
            style: AppTheme.lato(
              fontSize: large ? 11 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: past ? c.textMuted : c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoUpcomingBanner extends StatelessWidget {
  const _NoUpcomingBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: c.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderFaint),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 30, color: c.accentGold),
          const SizedBox(height: 10),
          Text(
            'No upcoming events',
            style: AppTheme.cormorantGaramond(
              fontSize: 18,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Past gatherings are listed below.',
            textAlign: TextAlign.center,
            style: AppTheme.lato(fontSize: 12.5, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Icon + text meta line used across event/news cards.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.trailing,
    this.small = false,
  });

  final IconData icon;
  final String text;
  final String? trailing;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (text.trim().isEmpty && (trailing == null || trailing!.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Icon(icon, size: small ? 13 : 15, color: c.accentGold.o(0.8)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.lato(
              fontSize: small ? 12 : 13,
              color: c.textSecondary,
            ),
          ),
        ),
        if (trailing != null && trailing!.isNotEmpty)
          Text(
            trailing!,
            style: AppTheme.lato(fontSize: small ? 11 : 12, color: c.textMuted),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.lato(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: fg,
        ),
      ),
    );
  }
}
