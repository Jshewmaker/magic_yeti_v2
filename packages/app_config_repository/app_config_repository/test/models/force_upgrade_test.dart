// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

// ignore_for_file: prefer_const_constructors
import 'package:app_config_repository/app_config_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForceUpgrade', () {
    test('supports value equality', () {
      expect(
        ForceUpgrade(isUpgradeRequired: false),
        ForceUpgrade(isUpgradeRequired: false),
      );
      expect(
        ForceUpgrade(isUpgradeRequired: true),
        isNot(ForceUpgrade(isUpgradeRequired: false)),
      );
    });
  });
}
