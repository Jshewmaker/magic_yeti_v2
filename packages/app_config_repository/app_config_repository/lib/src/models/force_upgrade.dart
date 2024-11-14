// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:equatable/equatable.dart';

/// {@template force_upgrade}
/// Model used to encapsulate configuration information
/// regarding force upgrade.
///
/// Includes a `bool` [isUpgradeRequired] which determines if
/// the current application requires a force upgrade as well as
/// an [upgradeUrl] to link to the latest version of the application.
/// {@endtemplate}
class ForceUpgrade extends Equatable {
  /// {@macro force_upgrade}
  const ForceUpgrade({
    required this.isUpgradeRequired,
    this.upgradeUrl,
  });

  /// Whether an upgrade is required.
  final bool isUpgradeRequired;

  /// The url where users can upgrade the application.
  final String? upgradeUrl;

  @override
  List<Object?> get props => [isUpgradeRequired, upgradeUrl];
}
