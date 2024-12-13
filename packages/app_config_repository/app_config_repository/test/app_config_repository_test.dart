// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:app_config_repository/app_config_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// AppConfigRepository is exported and can be implemented
class _FakeAppConfigRepository extends AppConfigRepository {
  _FakeAppConfigRepository({required super.buildNumber});

  @override
  Stream<bool> isDownForMaintenance() {
    return const Stream.empty();
  }

  @override
  Stream<ForceUpgrade> isForceUpgradeRequired() {
    return const Stream.empty();
  }
}

void main() {
  group('AppConfigRepository', () {
    test('throws AssertionError when build number is less than 1', () {
      expect(
        () => _FakeAppConfigRepository(buildNumber: 0),
        throwsAssertionError,
      );
    });

    test('can be implemented without error if buildNumber is greater than 0',
        () {
      expect(
        () => _FakeAppConfigRepository(buildNumber: 1),
        isNot(throwsException),
      );
    });
  });
}
