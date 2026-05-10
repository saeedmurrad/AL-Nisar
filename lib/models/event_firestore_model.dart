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

    return EventFirestoreModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      urduTitle: data['urduTitle'] as String? ?? '',
      day: (data['day'] as num?)?.toInt() ?? 1,
      monthAbbr: data['monthAbbr'] as String? ?? '',
      fullDateLine: data['fullDateLine'] as String? ?? '',
      shortDateLabel: data['shortDateLabel'] as String? ?? '',
      location: data['location'] as String? ?? '',
      timeLabel: data['timeLabel'] as String? ?? '',
      organizer: data['organizer'] as String? ?? 'Darbar Sharif',
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

