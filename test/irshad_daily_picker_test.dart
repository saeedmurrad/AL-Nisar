import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/models/irshad_firestore_model.dart';
import 'package:spiritual_learning_app/services/irshad_daily_picker.dart';

void main() {
  final items = List.generate(
    10,
    (i) => IrshadFirestoreModel(
      id: 'irshad_$i',
      dateLabel: 'Day $i',
      text: 'Text $i',
      imageUrl: '',
      createdAt: DateTime(2024, 1, i + 1),
      isActive: true,
    ),
  );

  test('same calendar day picks the same index', () {
    final day = DateTime(2026, 6, 22);
    final a = IrshadDailyPicker.dailyRandomIndex(items.length, day);
    final b = IrshadDailyPicker.dailyRandomIndex(items.length, day);
    expect(a, b);
  });

  test('pickForDay returns stable item for a given date', () {
    final day = DateTime(2026, 3, 15);
    final first = IrshadDailyPicker.pickForDay(items, day);
    final second = IrshadDailyPicker.pickForDay(items, day);
    expect(first, isNotNull);
    expect(first!.id, second!.id);
  });

  test('different days can pick different indices', () {
    final indices = <int>{};
    for (var day = 1; day <= 31; day++) {
      indices.add(
        IrshadDailyPicker.dailyRandomIndex(
          items.length,
          DateTime(2026, 1, day),
        ),
      );
    }
    expect(indices.length, greaterThan(1));
  });

  test('todayLabel formats current calendar date', () {
    expect(
      IrshadDailyPicker.todayLabel(DateTime(2026, 6, 23)),
      '23 Jun 2026',
    );
  });
}
