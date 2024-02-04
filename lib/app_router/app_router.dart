import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app_router/routes.dart';
import 'package:provider/provider.dart';

export 'routes.dart';

class AppRouter {
  AppRouter({
    GoRouter? goRouter,
  }) {
    _goRouter = goRouter ??
        GoRouter(
          routes: appRoutes,
          debugLogDiagnostics: kDebugMode,
        );
  }

  late final GoRouter _goRouter;

  /// Pushes an [AppRoute] route on top of the current navigation stack.
  ///
  /// Example routes:
  /// * [HomeRoute]
  /// * [LoginRoute]
  void push(AppRoute appRoute) {
    final path = appRoute.path;
    final data = appRoute.extra;

    _goRouter.push(
      path,
      extra: data,
    );
  }

  /// Pushes an [AppRoute] route on top of the current navigation stack.
  ///
  /// Example routes:
  /// * [HomeRoute]
  /// * [LoginRoute]
  void pushFromPath(String path, {Object? extra}) {
    _goRouter.push(
      path,
      extra: extra,
    );
  }

  /// Pop the top page off the GoRouter's page stack.
  void pop(dynamic value) => _goRouter.pop(value);

  /// Expose the [GoRouter]
  GoRouter get goRouter => _goRouter;

  static AppRouter of(BuildContext context) => context.read<AppRouter>();
}
