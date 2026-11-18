import 'package:formz/formz.dart';

/// Pin Form Input Validation Error
enum PinValidationError {
  /// Pin is empty
  empty,

  /// Pin is not exactly 4 digits
  invalidLength,

  /// Pin contains non-numeric characters
  nonNumeric,
}

/// {@template pin}
/// Reusable 4-digit numeric PIN form input.
/// {@endtemplate}
class Pin extends FormzInput<String, PinValidationError> {
  /// {@macro pin}
  const Pin.pure() : super.pure('');

  /// {@macro pin}
  const Pin.dirty([super.value = '']) : super.dirty();

  static final _numericRegExp = RegExp(r'^\d+$');

  @override
  PinValidationError? validator(String value) {
    if (value.isEmpty) return PinValidationError.empty;
    if (!_numericRegExp.hasMatch(value)) return PinValidationError.nonNumeric;
    if (value.length != 4) return PinValidationError.invalidLength;
    return null;
  }
}
