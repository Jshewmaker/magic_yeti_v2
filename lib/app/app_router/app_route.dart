// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/home.dart';
import 'package:magic_yeti/onboarding/onboarding.dart';

extension AppStatusRoute on AppStatus {
  String get route {
    switch (this) {
      case AppStatus.onboardingRequired:
        return OnboardingPage.routeName;
      case AppStatus.downForMaintenance:
      case AppStatus.forceUpgradeRequired:
      case AppStatus.unauthenticated:
      case AppStatus.authenticated:
      case AppStatus.anonymous:
        return HomePage.routeName;
    }
  }
}

class AppRoute extends GoRoute {
  AppRoute({
    required super.path,
    super.name,
    super.builder,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.routes = const <RouteBase>[],
    this.appStatus = AppStatus.authenticated,
  });

  final AppStatus appStatus;

}
