import 'package:formz/formz.dart';

/// Username Form Input Validation Error
enum UsernameValidationError {
  /// Username is empty or whitespace-only.
  empty,

  /// Username is shorter than [Username.minLength] after trimming.
  tooShort,

  /// Username is longer than [Username.maxLength] after trimming.
  tooLong,
}

/// {@template username}
/// Reusable username form input.
///
/// Validates the trimmed value; callers persist `value.trim()` so stored
/// usernames never carry edge whitespace.
/// {@endtemplate}
class Username extends FormzInput<String, UsernameValidationError> {
  /// {@macro username}
  const Username.pure() : super.pure('');

  /// {@macro username}
  const Username.dirty([super.value = '']) : super.dirty();

  /// Minimum trimmed length — matches the server-side username search's
  /// 2-character minimum query, so every valid username is discoverable.
  static const minLength = 2;

  /// Maximum trimmed length.
  static const maxLength = 30;

  @override
  UsernameValidationError? validator(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return UsernameValidationError.empty;
    if (trimmed.length < minLength) return UsernameValidationError.tooShort;
    if (trimmed.length > maxLength) return UsernameValidationError.tooLong;
    return null;
  }
}
