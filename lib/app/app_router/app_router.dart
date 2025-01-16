import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/app_router/app_route.dart';
import 'package:magic_yeti/app/app_router/go_router_refresh_stream.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/life_counter/view/game_over_page.dart';
import 'package:magic_yeti/life_counter/view/view.dart';
import 'package:magic_yeti/login/login.dart';
import 'package:magic_yeti/reset_password/reset_password.dart';
import 'package:magic_yeti/sign_up/sign_up.dart';

class AppRouter {
  AppRouter({
    required AppBloc appBloc,
    required GlobalKey<NavigatorState> navigatorKey,
    String? initialLocation = HomePage.routeName,
    List<NavigatorObserver> navigatorObservers = const [],
  }) {
    _currentStatus = appBloc.state.status;
    _goRouter = _routes(
      initialLocation,
      navigatorObservers,
      appBloc,
      navigatorKey,
    );
  }

  late final GoRouter _goRouter;
  late AppStatus _currentStatus;

  GoRouter get routes => _goRouter;

  GoRouter _routes(
    String? initialLocation,
    List<NavigatorObserver> navigatorObservers,
    AppBloc appBloc,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: GoRouterRefreshStream(appBloc.stream),
      observers: navigatorObservers,
      navigatorKey: navigatorKey,
      debugLogDiagnostics: true,
      onException: (context, state, router) {
        router.go(_currentStatus.route);
      },
      routes: [
        AppRoute(
          name: HomePage.routeName,
          path: HomePage.routeName,
          pageBuilder: (context, state) => NoTransitionPage(
            name: HomePage.routeName,
            child: HomePage.pageBuilder(context, state),
          ),
        ),
        AppRoute(
          name: GamePage.routeName,
          path: GamePage.routePath,
          pageBuilder: (context, state) => NoTransitionPage(
            name: GamePage.routePath,
            child: GamePage.pageBuilder(context, state),
          ),
          routes: [
            AppRoute(
              name: GameOverPage.routeName,
              path: GameOverPage.routePath,
              pageBuilder: (context, state) => NoTransitionPage(
                name: GameOverPage.routeName,
                child: GameOverPage.pageBuilder(context, state),
              ),
            ),
          ],
        ),
        AppRoute(
          name: LoginPage.routeName,
          path: LoginPage.routeName,
          appStatus: AppStatus.unauthenticated,
          pageBuilder: (context, state) => NoTransitionPage(
            name: LoginPage.routeName,
            child: LoginPage.pageBuilder(context, state),
          ),
          routes: [
            AppRoute(
              name: ResetPasswordPage.routeName,
              path: ResetPasswordPage.routeName,
              appStatus: AppStatus.unauthenticated,
              builder: ResetPasswordPage.pageBuilder,
            ),
          ],
        ),
        AppRoute(
          name: SignUpPage.routeName,
          path: SignUpPage.routeName,
          appStatus: AppStatus.unauthenticated,
          builder: SignUpPage.pageBuilder,
        ),
      ],
    );
  }
}
