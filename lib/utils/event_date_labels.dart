/// Formats event calendar fields from a single [DateTime].
class EventDateLabels {
  EventDateLabels._();

  static const _fullMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String monthAbbr(DateTime date) =>
      _shortMonths[date.month - 1].toUpperCase();

  static String fullDateLine(DateTime date) =>
      '${date.day} ${_fullMonths[date.month - 1]} ${date.year}';

  static String shortDateLabel(DateTime date) =>
      '${date.day} ${_shortMonths[date.month - 1]}';

  static String newsDateLabel(DateTime date) =>
      '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';

  static int day(DateTime date) => date.day;

  /// Best-effort parse from stored event fields.
  static DateTime parse({
    required String fullDateLine,
    required int day,
    required String monthAbbr,
  }) {
    final parts = fullDateLine.trim().split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final parsedDay = int.tryParse(parts.first);
      final year = int.tryParse(parts.last);
      final month = _monthIndex(parts[1]);
      if (parsedDay != null && year != null && month != null) {
        return DateTime(year, month, parsedDay);
      }
    }

    final abbr = monthAbbr.trim().toUpperCase();
    for (var i = 0; i < _shortMonths.length; i++) {
      if (_shortMonths[i].toUpperCase() == abbr && day > 0) {
        final yearMatch = RegExp(r'(20\d{2})').firstMatch(fullDateLine);
        final year =
            int.tryParse(yearMatch?.group(1) ?? '') ?? DateTime.now().year;
        return DateTime(year, i + 1, day);
      }
    }

    return DateTime.now();
  }

  static int? _monthIndex(String token) {
    final t = token.trim().toLowerCase();
    for (var i = 0; i < _fullMonths.length; i++) {
      if (_fullMonths[i].toLowerCase() == t) return i + 1;
    }
    for (var i = 0; i < _shortMonths.length; i++) {
      if (_shortMonths[i].toLowerCase() == t) return i + 1;
    }
    return null;
  }
}
