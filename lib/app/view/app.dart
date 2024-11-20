import 'package:app_config_repository/app_config_repository.dart';
import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/app_router/app_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:user_repository/user_repository.dart';

class App extends StatelessWidget {
  const App({
    required AppConfigRepository appConfigRepository,
    required UserRepository userRepository,
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    required ScryfallRepository scryfallRepository,
    required User user,
    super.key,
  })  : _appConfigRepository = appConfigRepository,
        _userRepository = userRepository,
        _scryfallRepository = scryfallRepository,
        _firebaseDatabaseRepository = firebaseDatabaseRepository,
        _user = user;

  final FirebaseDatabaseRepository _firebaseDatabaseRepository;
  final ScryfallRepository _scryfallRepository;
  final AppConfigRepository _appConfigRepository;
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AppBloc(
              appConfigRepository: _appConfigRepository,
              userRepository: _userRepository,
              user: _user,
            ),
          ),
          BlocProvider(
            create: (_) => GameBloc(firebase: _firebaseDatabaseRepository),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
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
      theme: const AppTheme().themeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => child!,
      routerConfig: _appRouter.routes,
    );
  }
}
