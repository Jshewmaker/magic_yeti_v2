// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'dart:async';

import 'package:app_config_repository/app_config_repository.dart';

/// {@template fake_app_config_repository}
/// A fake implementation of [AppConfigRepository].
///
/// See also:
///
/// * [changeIsDownForMaintenance], which reports a new status change of the
///  [isDownForMaintenance] stream.
/// * [changeIsForceUpgradeRequired], which reports a new status change of the
/// [isForceUpgradeRequired] stream.
/// {@endtemplate}
class FakeAppConfigRepository extends AppConfigRepository {
  /// {@macro fake_app_config_repository}
  FakeAppConfigRepository()
      : _isDownForMaintenanceStream = StreamController<bool>.broadcast(),
        _isForceUpgradeRequiredStream =
            StreamController<ForceUpgrade>.broadcast(),
        super(buildNumber: 1);

  /// The latest status of the [isDownForMaintenance] stream.
  ///
  /// If `null`, the [isDownForMaintenance] stream has not yet added any
  /// statuses.
  bool? _isDownForMaintenance;

  final StreamController<bool> _isDownForMaintenanceStream;

  /// The latest status of the [isForceUpgradeRequired] stream.
  ///
  /// If `null`, the [isForceUpgradeRequired] stream has not yet added any
  /// statuses.
  ForceUpgrade? _isForceUpgradeRequired;

  final StreamController<ForceUpgrade> _isForceUpgradeRequiredStream;

  /// Reports a new status change of the [isDownForMaintenance] stream.
  ///
  /// If the new status is different from the current status, the new status
  /// will be emitted to the [isDownForMaintenance] stream.
  ///
  /// If the new status is the same as the current status, nothing will happen.
  void changeIsDownForMaintenance({required bool isDownForMaintenance}) {
    assert(
      !_isDownForMaintenanceStream.isClosed,
      'Cannot change isDownForMaintenance after the stream has been closed.',
    );

    if (isDownForMaintenance != _isDownForMaintenance) {
      _isDownForMaintenanceStream.add(isDownForMaintenance);
      _isDownForMaintenance = isDownForMaintenance;
    }
  }

  @override
  Stream<bool> isDownForMaintenance() {
    assert(
      !_isDownForMaintenanceStream.isClosed,
      'Cannot access isDownForMaintenance after the stream has been closed.',
    );

    return _isDownForMaintenanceStream.stream;
  }

  /// Reports a new status change of the [isForceUpgradeRequired] stream.
  ///
  /// If the new status is different from the current status, the new status
  /// will be emitted to the [isForceUpgradeRequired] stream.
  ///
  /// If the new status is the same as the current status, nothing will happen.
  void changeIsForceUpgradeRequired({required ForceUpgrade forceUpgrade}) {
    assert(
      !_isForceUpgradeRequiredStream.isClosed,
      'Cannot change isForceUpgradeRequired after the stream has been closed.',
    );

    if (forceUpgrade != _isForceUpgradeRequired) {
      _isForceUpgradeRequiredStream.add(forceUpgrade);
      _isForceUpgradeRequired = forceUpgrade;
    }
  }

  @override
  Stream<ForceUpgrade> isForceUpgradeRequired() {
    assert(
      !_isForceUpgradeRequiredStream.isClosed,
      'Cannot access isForceUpgradeRequired after the stream has been closed.',
    );

    return _isForceUpgradeRequiredStream.stream;
  }

  /// Closes the [FakeAppConfigRepository].
  ///
  /// This should be called once the [FakeAppConfigRepository] is no longer
  /// needed so that any resources used by the [FakeAppConfigRepository] can
  /// be released.
  void close() {
    assert(
      !_isForceUpgradeRequiredStream.isClosed,
      'Cannot close FakeAppConfigRepository after it has already been closed.',
    );

    _isDownForMaintenanceStream.close();
    _isForceUpgradeRequiredStream.close();
  }
}
