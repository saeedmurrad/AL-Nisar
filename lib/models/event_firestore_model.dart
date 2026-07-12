import '../config/news_event_defaults.dart';
import '../utils/event_date_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventFirestoreModel {
  const EventFirestoreModel({
    required this.id,
    required this.title,
    required this.urduTitle,
    required this.day,
    required this.monthAbbr,
    required this.fullDateLine,
    required this.shortDateLabel,
    required this.location,
    required this.timeLabel,
    required this.organizer,
    required this.descriptionLines,
    required this.createdAt,
    required this.isActive,
  });

  final String id;
  final String title;
  final String urduTitle;
  final int day;
  final String monthAbbr;
  final String fullDateLine;
  final String shortDateLabel;
  final String location;
  final String timeLabel;
  final String organizer;
  final List<String> descriptionLines;
  final DateTime createdAt;
  final bool isActive;

  /// The event's actual calendar date, parsed from its stored date fields.
  DateTime get eventDate => EventDateLabels.parse(
    fullDateLine: fullDateLine,
    day: day,
    monthAbbr: monthAbbr,
  );

  /// True once the whole event day has elapsed (so an event happening today
  /// still counts as upcoming).
  bool get isPast {
    final d = eventDate;
    final endOfDay = DateTime(d.year, d.month, d.day, 23, 59, 59);
    return endOfDay.isBefore(DateTime.now());
  }

  /// True when the event falls on today's date.
  bool get isToday {
    final d = eventDate;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  factory EventFirestoreModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (ts is Timestamp) createdAt = ts.toDate();

    final raw = data['descriptionLines'];
    final lines = <String>[];
    if (raw is List) {
      for (final p in raw) {
        if (p is String && p.trim().isNotEmpty) lines.add(p);
      }
    }

    var fullDateLine = data['fullDateLine'] as String? ?? '';
    var day = (data['day'] as num?)?.toInt() ?? 1;
    var monthAbbr = data['monthAbbr'] as String? ?? '';
    var shortDateLabel = data['shortDateLabel'] as String? ?? '';

    if (fullDateLine.trim().isNotEmpty) {
      final parsed = EventDateLabels.parse(
        fullDateLine: fullDateLine,
        day: day,
        monthAbbr: monthAbbr,
      );
      day = EventDateLabels.day(parsed);
      monthAbbr = EventDateLabels.monthAbbr(parsed);
      shortDateLabel = EventDateLabels.shortDateLabel(parsed);
    } else if (day > 0 && monthAbbr.trim().isNotEmpty) {
      final parsed = EventDateLabels.parse(
        fullDateLine: fullDateLine,
        day: day,
        monthAbbr: monthAbbr,
      );
      fullDateLine = EventDateLabels.fullDateLine(parsed);
      shortDateLabel = EventDateLabels.shortDateLabel(parsed);
    }

    return EventFirestoreModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      urduTitle: data['urduTitle'] as String? ?? '',
      day: day,
      monthAbbr: monthAbbr,
      fullDateLine: fullDateLine,
      shortDateLabel: shortDateLabel,
      location: data['location'] as String? ?? '',
      timeLabel: data['timeLabel'] as String? ?? '',
      organizer:
          data['organizer'] as String? ?? NewsEventDefaults.eventOrganizer,
      descriptionLines: lines,
      createdAt: createdAt,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'urduTitle': urduTitle,
      'day': day,
      'monthAbbr': monthAbbr,
      'fullDateLine': fullDateLine,
      'shortDateLabel': shortDateLabel,
      'location': location,
      'timeLabel': timeLabel,
      'organizer': organizer,
      'descriptionLines': descriptionLines,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}
