import 'package:firebase_database_repository/models/models.dart';
import 'package:test/test.dart';

void main() {
  group('UserProfileModel', () {
    test('hasPin defaults false and round-trips through json', () {
      const model = UserProfileModel(id: 'u1', hasPin: true);
      final decoded = UserProfileModel.fromJson(model.toJson());
      expect(decoded.hasPin, isTrue);
      expect(UserProfileModel.fromJson(const {'id': 'u2'}).hasPin, isFalse);
    });

    group('isComplete', () {
      test('true when onboarded with username and hasPin', () {
        const m = UserProfileModel(
          id: 'u',
          username: 'josh',
          hasPin: true,
          onboardingComplete: true,
        );
        expect(m.isComplete, isTrue);
      });

      test('legacy unmigrated pin field counts as having a PIN', () {
        const m = UserProfileModel(
          id: 'u',
          username: 'josh',
          pin: 'somelegacyhash',
          onboardingComplete: true,
        );
        expect(m.isComplete, isTrue);
      });

      test('false when missing username, PIN, or onboarding flag', () {
        const base = UserProfileModel(
          id: 'u',
          username: 'josh',
          hasPin: true,
          onboardingComplete: true,
        );
        expect(base.copyWith(username: '').isComplete, isFalse);
        expect(
          const UserProfileModel(
            id: 'u',
            username: 'josh',
            onboardingComplete: true,
          ).isComplete,
          isFalse,
        );
        expect(base.copyWith(onboardingComplete: false).isComplete, isFalse);
      });
    });
  });
}
