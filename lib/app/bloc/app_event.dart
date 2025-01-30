// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

part of 'app_bloc.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object> get props => [];
}

class AppLogoutRequested extends AppEvent {
  const AppLogoutRequested();
}

class AppUserAccountDeleted extends AppEvent {
  const AppUserAccountDeleted();
}

class AppDownForMaintenanceStatusChanged extends AppEvent {
  @visibleForTesting
  const AppDownForMaintenanceStatusChanged({this.isDownForMaintenance = false});

  final bool isDownForMaintenance;

  @override
  List<Object> get props => [isDownForMaintenance];
}

class AppForceUpgradeStatusChanged extends AppEvent {
  @visibleForTesting
  const AppForceUpgradeStatusChanged(this.forceUpgrade);

  final ForceUpgrade forceUpgrade;

  @override
  List<Object> get props => [forceUpgrade];
}

class AppUserChanged extends AppEvent {
  @visibleForTesting
  const AppUserChanged(this.user);

  final User user;

  @override
  List<Object> get props => [user];
}

class AppOnboardingCompleted extends AppEvent {
  const AppOnboardingCompleted();
}
