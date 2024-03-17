import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/life_counter/life_counter.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:magic_yeti/player/models/player.dart';
import 'package:magic_yeti/player/view/customize_player_page.dart';

final appRoutes = [
  HomeRoute.route,
  LifeCounterRoute.route,
];

abstract class AppRoute extends Equatable {
  const AppRoute();

  Object? get extra => null;

  String get path;

  @override
  List<Object?> get props => [path, extra];
}

class LifeCounterRoute extends AppRoute {
  const LifeCounterRoute() : super();

  @override
  String get path => '/life_counter';

  static RouteBase get route => ShellRoute(
        builder: (context, state, child) {
          return BlocProvider(
            create: (context) => PlayerBloc(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/life_counter',
            builder: (context, state) {
              return const LifeCounterPage();
            },
            routes: [
              CustomizePlayerRoute.route,
            ],
          )
        ],
      );
}

class HomeRoute extends AppRoute {
  const HomeRoute() : super();

  @override
  String get path => '/';

  static GoRoute get route => GoRoute(
        path: '/',
        builder: (context, state) {
          return const HomePage();
        },
      );
}

class CustomizePlayerRoute extends AppRoute {
  const CustomizePlayerRoute() : super();

  @override
  String get path => 'customize_player';

  String get name => 'customizePlayer';

  static GoRoute get route => GoRoute(
        name: 'customizePlayer',
        path: 'customize_player',
        builder: (context, state) {
          return CustomizePlayerPage(
            player: state.extra! as Player,
          );
        },
      );
}
