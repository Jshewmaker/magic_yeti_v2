// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'dart:async';

import 'package:app_config_repository/app_config_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:user_repository/user_repository.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required AppConfigRepository appConfigRepository,
    required UserRepository userRepository,
    required User user,
  })  : _userRepository = userRepository,
        super(
          user == User.unauthenticated
              ? const AppState.unauthenticated()
              : AppState.authenticated(user),
        ) {
    on<AppDownForMaintenanceStatusChanged>(_onDownForMaintenanceStatusChanged);
    on<AppForceUpgradeStatusChanged>(_onForceUpgradeStatusChanged);
    on<AppUserChanged>(_onUserChanged);
    on<AppOnboardingCompleted>(_onOnboardingCompleted);
    on<AppLogoutRequested>(_onLogoutRequested);
    on<AppUserAccountDeleted>(_onUserAccountDeleted);

    _forceUpgradeSubscription = appConfigRepository
        .isForceUpgradeRequired()
        .listen(_forceUpgradeStatusChanged);
    _isDownForMaintenanceSubscription = appConfigRepository
        .isDownForMaintenance()
        .listen(_downForMaintenanceStatusChanged);
    _userSubscription = _userRepository.user.listen(_userChanged);
  }

  final UserRepository _userRepository;
  late StreamSubscription<ForceUpgrade> _forceUpgradeSubscription;
  late StreamSubscription<bool> _isDownForMaintenanceSubscription;
  late StreamSubscription<User> _userSubscription;

  void _downForMaintenanceStatusChanged(bool isDownForMaintenance) {
    add(
      AppDownForMaintenanceStatusChanged(
        isDownForMaintenance: isDownForMaintenance,
      ),
    );
  }

  void _forceUpgradeStatusChanged(ForceUpgrade forceUpgrade) {
    add(AppForceUpgradeStatusChanged(forceUpgrade));
  }

  void _userChanged(User user) => add(AppUserChanged(user));

  void _onDownForMaintenanceStatusChanged(
    AppDownForMaintenanceStatusChanged event,
    Emitter<AppState> emit,
  ) {
    if (event.isDownForMaintenance) {
      return emit(AppState.downForMaintenance(state.user));
    }

    if (state.status != AppStatus.downForMaintenance) return;

    state.user == User.unauthenticated
        ? emit(const AppState.unauthenticated())
        : emit(AppState.authenticated(state.user));
  }

  void _onForceUpgradeStatusChanged(
    AppForceUpgradeStatusChanged event,
    Emitter<AppState> emit,
  ) {
    if (event.forceUpgrade.isUpgradeRequired) {
      return emit(
        AppState.forceUpgradeRequired(event.forceUpgrade, state.user),
      );
    }
    if (state.status != AppStatus.forceUpgradeRequired) {
      return emit(state);
    }
    return state.user == User.unauthenticated
        ? emit(const AppState.unauthenticated())
        : emit(AppState.authenticated(state.user));
  }

  void _onUserChanged(AppUserChanged event, Emitter<AppState> emit) {
    switch (state.status) {
      case AppStatus.forceUpgradeRequired:
        return emit(
          AppState.forceUpgradeRequired(state.forceUpgrade, event.user),
        );
      case AppStatus.downForMaintenance:
        return emit(AppState.downForMaintenance(event.user));
      case AppStatus.authenticated:
      case AppStatus.unauthenticated:
      case AppStatus.onboardingRequired:
        return event.user == User.unauthenticated
            ? emit(const AppState.unauthenticated())
            : event.user.isNewUser
                ? emit(AppState.onboardingRequired(event.user))
                : emit(AppState.authenticated(event.user));
    }
  }

  void _onOnboardingCompleted(
    AppOnboardingCompleted event,
    Emitter<AppState> emit,
  ) {
    if (state.status == AppStatus.onboardingRequired) {
      return state.user == User.unauthenticated
          ? emit(const AppState.unauthenticated())
          : emit(AppState.authenticated(state.user));
    }
  }

  void _onLogoutRequested(AppLogoutRequested event, Emitter<AppState> emit) {
    unawaited(_userRepository.logOut());
  }

  void _onUserAccountDeleted(
    AppUserAccountDeleted event,
    Emitter<AppState> emit,
  ) {
    unawaited(_userRepository.deleteAccount());
  }

  @override
  Future<void> close() {
    _forceUpgradeSubscription.cancel();
    _isDownForMaintenanceSubscription.cancel();
    _userSubscription.cancel();
    return super.close();
  }
}
