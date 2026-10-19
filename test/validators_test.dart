import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/ui/login/validators.dart';

void main() {
  group('validateEmail', () {
    test('rejects empty and whitespace', () {
      expect(validateEmail(null), isNotNull);
      expect(validateEmail('   '), isNotNull);
    });

    test('rejects malformed addresses', () {
      expect(validateEmail('abc'), isNotNull);
      expect(validateEmail('a@b'), isNotNull);
      expect(validateEmail('a b@c.com'), isNotNull);
    });

    test('accepts valid address with surrounding spaces', () {
      expect(validateEmail(' a@b.com '), isNull);
    });
  });

  group('validatePassword', () {
    test('rejects empty and short passwords', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword('12345'), isNotNull);
    });

    test('accepts 6+ characters', () {
      expect(validatePassword('123456'), isNull);
    });
  });

  group('validateConfirmPassword', () {
    test('rejects empty and mismatch', () {
      expect(validateConfirmPassword('', 'secret1'), isNotNull);
      expect(validateConfirmPassword('secret2', 'secret1'), isNotNull);
    });

    test('accepts matching password', () {
      expect(validateConfirmPassword('secret1', 'secret1'), isNull);
    });
  });
}
