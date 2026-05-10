import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/dummy_data.dart';
import '../services/news_events_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fallback = DummyData.eventById(eventId) ?? DummyData.eventsList.first;
    final onGold = Theme.of(context).brightness == Brightness.dark
        ? c.backgroundPrimary
        : c.textPrimary;

    return FutureBuilder(
      future: NewsEventsService().getEventById(eventId),
      builder: (context, snap) {
        final doc = snap.data;
        final title = doc?.title.isNotEmpty == true ? doc!.title : fallback.title;
        final fullDateLine = doc?.fullDateLine.isNotEmpty == true
            ? doc!.fullDateLine
            : fallback.fullDateLine;
        final location = doc?.location.isNotEmpty == true ? doc!.location : fallback.location;
        final timeLabel = doc?.timeLabel.isNotEmpty == true ? doc!.timeLabel : fallback.timeLabel;
        final organizer = doc?.organizer.isNotEmpty == true ? doc!.organizer : fallback.organizer;
        final lines = (doc?.descriptionLines.isNotEmpty == true)
            ? doc!.descriptionLines
            : (fallback.descriptionLines.isNotEmpty
                ? fallback.descriptionLines
                : [
                    'Details will be confirmed closer to the date.',
                    'Please travel with adab and patience.',
                    'Contact the organizers for accessibility needs.',
                  ]);

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: c.backgroundSurface,
                padding: const EdgeInsets.fromLTRB(10, 18, 16, 14),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
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
                              title,
                              style: AppTheme.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fullDateLine,
                              style: AppTheme.lato(
                                fontSize: 13,
                                color: c.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: c.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: AppTheme.lato(
                                      fontSize: 13,
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final line in lines) ...[
                      Text(
                        line,
                        style: AppTheme.lato(
                          fontSize: 15,
                          height: 1.65,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Date', value: fullDateLine),
                    _InfoRow(label: 'Time', value: timeLabel),
                    _InfoRow(label: 'Location', value: location),
                    _InfoRow(label: 'Organizer', value: organizer),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.accentGold,
                          foregroundColor: onGold,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add to Calendar',
                          style: AppTheme.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: onGold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.accentGold,
                          side: BorderSide(color: c.accentGold, width: 1.1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Share Event',
                          style: AppTheme.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: c.accentGold,
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
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTheme.lato(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.lato(
                fontSize: 14,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _backSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M14.5 5.5L8 12l6.5 6.5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
