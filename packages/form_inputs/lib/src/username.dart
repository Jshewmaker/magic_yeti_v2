import 'package:formz/formz.dart';

/// Username Form Input Validation Error
enum UsernameValidationError {
  /// Username is empty (should have at least 1 character)
  empty
}

/// {@template username}
/// Reusable username form input.
/// {@endtemplate}
class Username extends FormzInput<String, UsernameValidationError> {
  /// {@macro username}
  const Username.pure() : super.pure('');

  /// {@macro username}
  const Username.dirty([super.value = '']) : super.dirty();

  @override
  UsernameValidationError? validator(String value) {
    return value.isNotEmpty ? null : UsernameValidationError.empty;
  }
}
