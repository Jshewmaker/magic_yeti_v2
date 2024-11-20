// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';

extension AppStatusRoute on AppStatus {
  String get route {
    switch (this) {
      case AppStatus.onboardingRequired:
      case AppStatus.downForMaintenance:
      case AppStatus.forceUpgradeRequired:
      case AppStatus.unauthenticated:
      case AppStatus.authenticated:
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

  @override
  GoRouterRedirect get redirect => (context, state) {
        final currentStatus = context.read<AppBloc>().state.status;
        //  return currentStatus == appStatus ? null : currentStatus.route;
      };
}
