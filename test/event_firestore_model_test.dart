import 'package:spiritual_learning_app/models/event_firestore_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventFirestoreModel.fromFirestore date fields', () {
    test('derives day and month from fullDateLine when day is missing', () {
      final doc = _FakeDoc({
        'title': 'Test Event',
        'fullDateLine': '26 June 2026',
        'isActive': true,
      });

      final event = EventFirestoreModel.fromFirestore(doc);

      expect(event.day, 26);
      expect(event.monthAbbr, 'JUN');
      expect(event.shortDateLabel, '26 Jun');
      expect(event.fullDateLine, '26 June 2026');
    });

    test('overrides stale day field when fullDateLine is authoritative', () {
      final doc = _FakeDoc({
        'title': 'Test Event',
        'day': 1,
        'monthAbbr': 'JUN',
        'fullDateLine': '26 June 2026',
        'shortDateLabel': '1 Jun',
        'isActive': true,
      });

      final event = EventFirestoreModel.fromFirestore(doc);

      expect(event.day, 26);
      expect(event.monthAbbr, 'JUN');
      expect(event.shortDateLabel, '26 Jun');
    });

    test('builds fullDateLine from day and month when fullDateLine is empty', () {
      final doc = _FakeDoc({
        'title': 'Test Event',
        'day': 26,
        'monthAbbr': 'JUN',
        'isActive': true,
      });

      final event = EventFirestoreModel.fromFirestore(doc);

      expect(event.day, 26);
      expect(event.monthAbbr, 'JUN');
      expect(event.fullDateLine, contains('26'));
      expect(event.fullDateLine, contains('June'));
    });
  });
}

class _FakeDoc implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDoc(this._data, {this.id = 'test-event-id'});

  final Map<String, dynamic> _data;

  @override
  final String id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
