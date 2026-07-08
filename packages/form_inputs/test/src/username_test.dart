import 'package:form_inputs/form_inputs.dart';
import 'package:test/test.dart';

void main() {
  group('Username', () {
    test('pure empty value reports no display error and is not valid', () {
      const username = Username.pure();
      expect(username.displayError, isNull);
      expect(username.isValid, isFalse);
    });

    test('empty dirty value has the empty error', () {
      const username = Username.dirty();
      expect(username.error, UsernameValidationError.empty);
    });

    test('whitespace-only value has the empty error', () {
      const username = Username.dirty('   ');
      expect(username.error, UsernameValidationError.empty);
    });

    test('one character after trimming is too short', () {
      const username = Username.dirty(' a ');
      expect(username.error, UsernameValidationError.tooShort);
    });

    test('31 characters after trimming is too long', () {
      final username = Username.dirty('a' * 31);
      expect(username.error, UsernameValidationError.tooLong);
    });

    test('2 and 30 trimmed characters are valid', () {
      expect(const Username.dirty('ab').isValid, isTrue);
      expect(Username.dirty(' ${'a' * 30} ').isValid, isTrue);
    });

    test('interior spaces are allowed', () {
      expect(const Username.dirty('Cool Name').isValid, isTrue);
    });
  });
}
