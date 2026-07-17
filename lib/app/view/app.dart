import 'package:app_config_repository/app_config_repository.dart';
import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/app_router/app_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:user_repository/user_repository.dart';

class App extends StatelessWidget {
  const App({
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    required AppConfigRepository appConfigRepository,
    required UserRepository userRepository,
    required ScryfallRepository scryfallRepository,
    required PlayerRepository playerRepository,
    required CommanderLibraryRepository commanderLibraryRepository,
    required User user,
    super.key,
  })  : _appConfigRepository = appConfigRepository,
        _userRepository = userRepository,
        _scryfallRepository = scryfallRepository,
        _firebaseDatabaseRepository = firebaseDatabaseRepository,
        _playerRepository = playerRepository,
        _commanderLibraryRepository = commanderLibraryRepository,
        _user = user;

  final FirebaseDatabaseRepository _firebaseDatabaseRepository;
  final ScryfallRepository _scryfallRepository;
  final AppConfigRepository _appConfigRepository;
  final PlayerRepository _playerRepository;
  final CommanderLibraryRepository _commanderLibraryRepository;
  final UserRepository _userRepository;

  final User _user;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _appConfigRepository),
        RepositoryProvider.value(value: _scryfallRepository),
        RepositoryProvider.value(value: _firebaseDatabaseRepository),
        RepositoryProvider.value(value: _userRepository),
        RepositoryProvider.value(value: _playerRepository),
        RepositoryProvider.value(value: _commanderLibraryRepository),
        RepositoryProvider.value(value: _user),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AppBloc(
              appConfigRepository: _appConfigRepository,
              userRepository: _userRepository,
              firebaseDatabaseRepository: _firebaseDatabaseRepository,
              user: _user,
            ),
          ),
          BlocProvider(
            lazy: false,
            create: (context) => GameBloc(
              playerRepository: _playerRepository,
              database: context.read<FirebaseDatabaseRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => MatchHistoryBloc(
              databaseRepository: context.read<FirebaseDatabaseRepository>(),
            )..add(
                LoadMatchHistory(
                  userId: _historyUserId(context.read<AppBloc>().state),
                ),
              ),
          ),
          BlocProvider(
            lazy: false,
            create: (context) => TimerBloc(),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

/// The user whose match history should be shown: the signed-in user, or
/// nobody (empty id clears the history) for any other auth state.
String _historyUserId(AppState state) {
  return state.status == AppStatus.authenticated ? state.user.id : '';
}

class AppView extends StatefulWidget {
  @visibleForTesting
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  late final AppRouter _appRouter;
  late final GlobalKey<NavigatorState> _navigatorKey;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
    _appRouter = AppRouter(
      appBloc: context.read<AppBloc>(),
      navigatorKey: _navigatorKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: const AppTheme().themeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return DeviceInfoProvider.fromMediaQuery(
          // Keep the match history subscribed to whoever is signed in;
          // sign-out clears it. Lives at the app root so it holds no matter
          // which screen is visible.
          child: BlocListener<AppBloc, AppState>(
            listenWhen: (previous, current) =>
                _historyUserId(previous) != _historyUserId(current),
            listener: (context, state) {
              context
                  .read<MatchHistoryBloc>()
                  .add(LoadMatchHistory(userId: _historyUserId(state)));
            },
            child: child!,
          ),
        );
      },
      routerConfig: _appRouter.routes,
    );
  }
}
