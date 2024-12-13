// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'dart:async';

import 'package:app_config_repository/app_config_repository.dart';

/// {@template app_config_repository}
/// Repository which manages determining whether the application
/// is in maintenance mode or needs to be force upgraded.
/// {@endtemplate}
abstract class AppConfigRepository {
  /// {@macro app_config_repository}
  AppConfigRepository({
    required this.buildNumber,
  }) : assert(buildNumber > 0, 'buildNumber must be greater than 0');

  /// Build number of the app
  final int buildNumber;

  /// Returns a [Stream<bool>] which indicates whether
  /// the current application status is down for maintenance.
  ///
  /// By default, [isDownForMaintenance] will emit `false`
  /// if unable to connected to the backend.
  Stream<bool> isDownForMaintenance();

  /// Returns a [Stream<ForceUpgrade>] which indicates whether
  /// the current application requires a force upgrade.
  Stream<ForceUpgrade> isForceUpgradeRequired();
}
