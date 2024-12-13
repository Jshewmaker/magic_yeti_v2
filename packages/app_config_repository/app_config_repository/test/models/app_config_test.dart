// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

// ignore_for_file: prefer_const_constructors
import 'package:app_config_repository/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    const androidUpgradeUrl = 'mock-android-upgrade-url';
    const downForMaintenance = false;
    const iosUpgradeUrl = 'mock-ios-upgrade-url';
    const minAndroidBuildNumber = 1;
    const minIosBuildNumber = 1;

    group('equatable props', () {
      test('are correct', () {
        expect(
          AppConfig(
            androidUpgradeUrl: androidUpgradeUrl,
            downForMaintenance: downForMaintenance,
            iosUpgradeUrl: iosUpgradeUrl,
            minAndroidBuildNumber: minAndroidBuildNumber,
            minIosBuildNumber: minIosBuildNumber,
          ).props,
          [
            androidUpgradeUrl,
            downForMaintenance,
            iosUpgradeUrl,
            minAndroidBuildNumber,
            minIosBuildNumber,
          ],
        );
      });
    });

    group('fromJson', () {
      test('correctly deserializes', () {
        final json = <String, dynamic>{
          'down_for_maintenance': true,
          'min_android_build_number': 1,
          'min_ios_build_number': 1,
          'android_upgrade_url': 'mock-android-upgrade-url',
          'ios_upgrade_url': 'mock-ios-upgrade-url',
        };
        expect(
          AppConfig.fromJson(json),
          equals(
            AppConfig(
              androidUpgradeUrl: 'mock-android-upgrade-url',
              downForMaintenance: true,
              iosUpgradeUrl: 'mock-ios-upgrade-url',
              minAndroidBuildNumber: 1,
              minIosBuildNumber: 1,
            ),
          ),
        );
      });
    });
  });
}
