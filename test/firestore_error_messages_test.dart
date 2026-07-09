import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spiritual_learning_app/utils/firestore_error_messages.dart';

void main() {
  group('sabaqAccessRequestErrorMessage', () {
    test('maps StateError codes', () {
      expect(
        sabaqAccessRequestErrorMessage(StateError('not_signed_in')),
        'Please sign in to request access.',
      );
      expect(
        sabaqAccessRequestErrorMessage(StateError('request_already_active')),
        'A request is already pending or approved for this Sabaq.',
      );
      expect(
        sabaqAccessRequestErrorMessage(StateError('not_next_sabaq')),
        'You can only request the next Sabaq in sequence.',
      );
    });

    test('maps FirebaseException codes', () {
      expect(
        sabaqAccessRequestErrorMessage(
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
        ),
        'Request not allowed. Sign out and sign in again, or contact admin.',
      );
      expect(
        sabaqAccessRequestErrorMessage(
          FirebaseException(plugin: 'cloud_firestore', code: 'unauthenticated'),
        ),
        'Session expired. Please sign in again.',
      );
      expect(
        sabaqAccessRequestErrorMessage(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
        'Network error. Check your connection and try again.',
      );
    });
  });
}
