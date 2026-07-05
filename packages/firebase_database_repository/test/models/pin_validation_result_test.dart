import 'package:firebase_database_repository/models/models.dart';
import 'package:test/test.dart';

void main() {
  group('PinValidationResult', () {
    test('value equality', () {
      expect(const PinValid(), const PinValid());
      expect(
        const PinInvalid(attemptsRemaining: 3),
        const PinInvalid(attemptsRemaining: 3),
      );
      expect(
        const PinInvalid(attemptsRemaining: 3),
        isNot(const PinInvalid(attemptsRemaining: 2)),
      );
      expect(
        PinLockedOut(lockedUntil: DateTime.utc(2026, 7, 3)),
        PinLockedOut(lockedUntil: DateTime.utc(2026, 7, 3)),
      );
      expect(const PinCheckUnavailable(), const PinCheckUnavailable());
    });

    test('subtypes are exhaustively switchable', () {
      String describe(PinValidationResult r) => switch (r) {
            PinValid() => 'valid',
            PinInvalid(:final attemptsRemaining) =>
              'invalid:$attemptsRemaining',
            PinLockedOut() => 'locked',
            PinCheckUnavailable() => 'unavailable',
          };
      expect(describe(const PinValid()), 'valid');
      expect(
        describe(const PinInvalid(attemptsRemaining: 2)),
        'invalid:2',
      );
    });
  });
}
