import 'dart:math';

import '../models/irshad_firestore_model.dart';

/// Picks one Irshad per calendar day using a date-seeded random index.
class IrshadDailyPicker {
  static int dailyRandomIndex(int length, [DateTime? now]) {
    if (length <= 0) return 0;
    final d = now ?? DateTime.now();
    final seed = d.year * 10000 + d.month * 100 + d.day;
    return Random(seed).nextInt(length);
  }

  static IrshadFirestoreModel? pickForDay(
    List<IrshadFirestoreModel> items, [
    DateTime? now,
  ]) {
    if (items.isEmpty) return null;
    final sorted = List<IrshadFirestoreModel>.from(items)
      ..sort((a, b) => a.id.compareTo(b.id));
    return sorted[dailyRandomIndex(sorted.length, now)];
  }

  static String todayLabel([DateTime? now]) {
    final d = now ?? DateTime.now();
    const months = [
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}
