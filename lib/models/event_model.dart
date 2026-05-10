class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.urduTitle,
    required this.day,
    required this.monthAbbr,
    required this.fullDateLine,
    required this.shortDateLabel,
    required this.location,
    required this.timeLabel,
    this.organizer = 'Darbar Sharif',
    this.descriptionLines = const [],
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
}
