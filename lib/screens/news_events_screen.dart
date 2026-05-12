import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/dummy_data.dart';
import '../models/event_firestore_model.dart';
import '../models/news_firestore_model.dart';
import '../services/news_events_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/standard_shell_header.dart';

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
                color: c.textPrimary,
              ),
            ),
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Row(
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
                    final list = snap.data;
                    final use = (list == null || list.isEmpty)
                        ? DummyData.newsList
                            .map(
                              (n) => NewsFirestoreModel(
                                id: n.id,
                                title: n.title,
                                category: n.category,
                                dateLabel: n.dateLabel,
                                imageUrl: n.imageUrl,
                                readTime: n.readTime,
                                bodyParagraphs: n.bodyParagraphs,
                                createdAt: DateTime.now(),
                                isActive: true,
                              ),
                            )
                            .toList()
                        : list;

                    final featured = use.isEmpty
                        ? NewsFirestoreModel(
                            id: DummyData.newsFeatured.id,
                            title: DummyData.newsFeatured.title,
                            category: DummyData.newsFeatured.category,
                            dateLabel: DummyData.newsFeatured.dateLabel,
                            imageUrl: DummyData.newsFeatured.imageUrl,
                            readTime: DummyData.newsFeatured.readTime,
                            bodyParagraphs: DummyData.newsFeatured.bodyParagraphs,
                            createdAt: DateTime.now(),
                            isActive: true,
                          )
                        : use.first;
                    final rest = use.length <= 1 ? <NewsFirestoreModel>[] : use.sublist(1);

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
                    final list = snap.data;
                    final use = (list == null || list.isEmpty)
                        ? DummyData.eventsList
                            .map(
                              (e) => EventFirestoreModel(
                                id: e.id,
                                title: e.title,
                                urduTitle: e.urduTitle,
                                day: e.day,
                                monthAbbr: e.monthAbbr,
                                fullDateLine: e.fullDateLine,
                                shortDateLabel: e.shortDateLabel,
                                location: e.location,
                                timeLabel: e.timeLabel,
                                organizer: e.organizer,
                                descriptionLines: e.descriptionLines,
                                createdAt: DateTime.now(),
                                isActive: true,
                              ),
                            )
                            .toList()
                        : list;

                    final next = use.isEmpty
                        ? EventFirestoreModel(
                            id: DummyData.eventsList.first.id,
                            title: DummyData.eventsList.first.title,
                            urduTitle: DummyData.eventsList.first.urduTitle,
                            day: DummyData.eventsList.first.day,
                            monthAbbr: DummyData.eventsList.first.monthAbbr,
                            fullDateLine: DummyData.eventsList.first.fullDateLine,
                            shortDateLabel: DummyData.eventsList.first.shortDateLabel,
                            location: DummyData.eventsList.first.location,
                            timeLabel: DummyData.eventsList.first.timeLabel,
                            organizer: DummyData.eventsList.first.organizer,
                            descriptionLines: DummyData.eventsList.first.descriptionLines,
                            createdAt: DateTime.now(),
                            isActive: true,
                          )
                        : use.first;

                    return _EventsTabFirestore(
                      nextEvent: next,
                      events: use,
                      onGold: onGold,
                    );
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
    final onGold = Theme.of(context).brightness == Brightness.dark
        ? c.backgroundPrimary
        : c.textPrimary;
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

class _NewsTabFirestore extends StatelessWidget {
  const _NewsTabFirestore({
    required this.featured,
    required this.items,
    required this.onGold,
  });

  final NewsFirestoreModel featured;
  final List<NewsFirestoreModel> items;
  final Color onGold;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        InkWell(
          onTap: () => context.push('/news-events/news-detail?id=${featured.id}'),
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: featured.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerPlaceholder(),
                    errorWidget: (context, url, error) =>
                        const GoldPatternError(),
                  ),
                ),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.backgroundPrimary.o(0.05),
                        c.backgroundPrimary.o(0.75),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: c.accentGold.o(0.95),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      featured.category,
                      style: AppTheme.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: onGold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 36,
                  child: Text(
                    featured.title,
                    style: AppTheme.cormorantGaramond(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Text(
                    featured.dateLabel,
                    style: AppTheme.lato(
                      fontSize: 11,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (n) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () =>
                  context.push('/news-events/news-detail?id=${n.id}'),
              child: Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: c.accentGold.o(0.35),
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CachedNetworkImage(
                          imageUrl: n.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => ShimmerPlaceholder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          errorWidget: (context, url, error) =>
                              const GoldPatternError(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.category.toUpperCase(),
                            style: TextStyle(
                              color: c.accentGold,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.title,
                            style: AppTheme.cormorantGaramond(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${n.dateLabel} · ${n.readTime}',
                            style: AppTheme.lato(
                              fontSize: 11,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventsTabFirestore extends StatelessWidget {
  const _EventsTabFirestore({
    required this.nextEvent,
    required this.events,
    required this.onGold,
  });

  final EventFirestoreModel nextEvent;
  final List<EventFirestoreModel> events;
  final Color onGold;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: c.accentGold,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT EVENT',
                style: AppTheme.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: onGold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Urs Mubarak 2026',
                style: AppTheme.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: onGold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: onGold),
                  const SizedBox(width: 8),
                  Text(
                    nextEvent.fullDateLine,
                    style: AppTheme.lato(
                      fontSize: 13,
                      color: onGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: onGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nextEvent.location,
                      style: AppTheme.lato(
                        fontSize: 13,
                        color: onGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push(
                    '/news-events/event-detail?id=${nextEvent.id}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onGold,
                    side: BorderSide(color: onGold, width: 1.1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: AppTheme.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: onGold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...events.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () =>
                  context.push('/news-events/event-detail?id=${e.id}'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.backgroundSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.borderDefault, width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: c.accentGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${e.day}',
                            style: AppTheme.lato(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: onGold,
                            ),
                          ),
                          Text(
                            e.monthAbbr,
                            style: TextStyle(
                              color: onGold.o(0.85),
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: AppTheme.cormorantGaramond(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              e.urduTitle,
                              style: AppTheme.amiriUrdu(
                                fontSize: 13,
                                height: 1.3,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: c.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  e.location,
                                  style: AppTheme.lato(
                                    fontSize: 12,
                                    color: c.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 14,
                                color: c.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                e.timeLabel,
                                style: AppTheme.lato(
                                  fontSize: 11,
                                  color: c.textMuted,
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
          ),
        ),
      ],
    );
  }
}
