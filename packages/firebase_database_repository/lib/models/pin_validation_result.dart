import 'package:equatable/equatable.dart';

/// {@template pin_validation_result}
/// Result of validating a friend's PIN via the `validatePin` callable.
/// {@endtemplate}
sealed class PinValidationResult extends Equatable {
  /// {@macro pin_validation_result}
  const PinValidationResult();

  @override
  List<Object?> get props => [];
}

/// The PIN was correct.
final class PinValid extends PinValidationResult {
  /// Creates a valid result.
  const PinValid();
}

/// The PIN was wrong; [attemptsRemaining] tries left before lockout.
final class PinInvalid extends PinValidationResult {
  /// Creates an invalid result.
  const PinInvalid({required this.attemptsRemaining});

  /// Attempts left before a lockout is applied.
  final int attemptsRemaining;

  @override
  List<Object?> get props => [attemptsRemaining];
}

/// Too many failed attempts; retry after [lockedUntil].
final class PinLockedOut extends PinValidationResult {
  /// Creates a locked-out result.
  const PinLockedOut({required this.lockedUntil});

  /// When the lockout expires.
  final DateTime lockedUntil;

  @override
  List<Object?> get props => [lockedUntil];
}

/// The check could not be performed (offline or server error).
final class PinCheckUnavailable extends PinValidationResult {
  /// Creates an unavailable result.
  const PinCheckUnavailable();
}
