// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

part of 'app_bloc.dart';

enum AppStatus {
  downForMaintenance,
  forceUpgradeRequired,
  onboardingRequired,
  authenticated,
  unauthenticated,
}

class AppState extends Equatable {
  const AppState._({
    required this.status,
    this.forceUpgrade = const ForceUpgrade(isUpgradeRequired: false),
    this.user = UserProfileModel.empty,
  });

  const AppState.downForMaintenance([
    UserProfileModel user = UserProfileModel.empty,
  ]) : this._(status: AppStatus.downForMaintenance, user: user);

  const AppState.forceUpgradeRequired(
    ForceUpgrade forceUpgrade, [
    UserProfileModel user = UserProfileModel.empty,
  ]) : this._(
          status: AppStatus.forceUpgradeRequired,
          forceUpgrade: forceUpgrade,
          user: user,
        );

  const AppState.authenticated(UserProfileModel user)
      : this._(status: AppStatus.authenticated, user: user);

  const AppState.onboardingRequired(UserProfileModel user)
      : this._(status: AppStatus.onboardingRequired, user: user);

  const AppState.unauthenticated() : this._(status: AppStatus.unauthenticated);

  final AppStatus status;
  final ForceUpgrade forceUpgrade;
  final UserProfileModel user;

  @override
  List<Object> get props => [status, forceUpgrade, user];
}
