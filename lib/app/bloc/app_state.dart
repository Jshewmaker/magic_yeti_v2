// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

part of 'app_bloc.dart';

enum AppStatus {
  downForMaintenance,
  forceUpgradeRequired,
  onboardingRequired,
  anonymous,
  authenticated,
  unauthenticated,
}

class AppState extends Equatable {
  const AppState._({
    required this.status,
    this.forceUpgrade = const ForceUpgrade(isUpgradeRequired: false),
    this.user = User.unauthenticated,
  });

  const AppState.downForMaintenance([
    User user = User.unauthenticated,
  ]) : this._(status: AppStatus.downForMaintenance, user: user);

  const AppState.forceUpgradeRequired(
    ForceUpgrade forceUpgrade, [
    User user = User.unauthenticated,
  ]) : this._(
          status: AppStatus.forceUpgradeRequired,
          forceUpgrade: forceUpgrade,
          user: user,
        );

  const AppState.authenticated(User user)
      : this._(status: AppStatus.authenticated, user: user);

  const AppState.onboardingRequired(User user)
      : this._(status: AppStatus.onboardingRequired, user: user);

  const AppState.unauthenticated() : this._(status: AppStatus.unauthenticated);

  const AppState.anonymous(User user)
      : this._(status: AppStatus.anonymous, user: user);

  final AppStatus status;
  final ForceUpgrade forceUpgrade;
  final User user;

  @override
  List<Object> get props => [status, forceUpgrade, user];
}
