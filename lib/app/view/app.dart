import 'package:api_client/api_client.dart';
import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app_router/app_router.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

class App extends StatelessWidget {
  const App({
    required this.apiClient,
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    required ScryfallRepository scryfallRepository,
    super.key,
  })  : _scryfallRepository = scryfallRepository,
        _firebaseDatabaseRepository = firebaseDatabaseRepository;

  final ApiClient apiClient;
  final FirebaseDatabaseRepository _firebaseDatabaseRepository;
  final ScryfallRepository _scryfallRepository;
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _scryfallRepository),
        RepositoryProvider.value(value: _firebaseDatabaseRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => GameBloc(firebase: _firebaseDatabaseRepository),
          ),
        ],
        child: Provider<AppRouter>(
          create: (context) => AppRouter(),
          child: const AppView(),
        ),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter.of(context);

    return MaterialApp.router(
      theme: const AppTheme().themeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter.goRouter,
    );
  }
}
