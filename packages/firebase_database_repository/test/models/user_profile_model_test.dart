import 'package:firebase_database_repository/models/models.dart';
import 'package:test/test.dart';

void main() {
  group('UserProfileModel', () {
    test('toJson omits null fields entirely (includeIfNull false)', () {
      const model = UserProfileModel(id: 'u1', username: 'josh');
      final json = model.toJson();
      expect(json.containsKey('pin'), isFalse);
      expect(json.containsKey('bio'), isFalse);
      expect(json['username'], 'josh');
    });

    test('usernameLower omitted when null, round-trips when set', () {
      const withUsername = UserProfileModel(id: 'u1', username: 'josh');
      expect(withUsername.toJson().containsKey('usernameLower'), isFalse);

      const withLower = UserProfileModel(
        id: 'u1',
        username: 'Josh',
        usernameLower: 'josh',
      );
      final decoded = UserProfileModel.fromJson(withLower.toJson());
      expect(decoded.usernameLower, 'josh');
    });

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
