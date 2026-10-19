import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/data/model/auth_failure.dart';

void main() {
  test('credential errors share one neutral message', () {
    for (final code in [
      'invalid-credential',
      'user-not-found',
      'wrong-password',
    ]) {
      expect(AuthFailure(code).message, 'Incorrect email or password.');
    }
  });

  test('known codes map to specific messages', () {
    expect(
      const AuthFailure('email-already-in-use').message,
      'An account already exists for this email.',
    );
    expect(
      const AuthFailure('weak-password').message,
      contains('at least 6 characters'),
    );
  });

  test('unknown code falls back to generic message', () {
    expect(
      const AuthFailure('something-new').message,
      'Something went wrong. Please try again.',
    );
  });
}
