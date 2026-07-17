import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/view/game_over_page.dart';
import 'package:magic_yeti/life_counter/view/game_page.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:user_repository/user_repository.dart';

import '../../helpers/pump_app.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockGameBloc extends MockBloc<GameEvent, GameState>
    implements GameBloc {}

class MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class _FakeGameModel extends Fake implements GameModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeGameModel());
  });

  group('GameOverView account-owner dropdown', () {
    late MockAppBloc appBloc;
    late MockGameBloc gameBloc;
    late MockTimerBloc timerBloc;
    late PlayerRepository playerRepository;
    late GameOverBloc gameOverBloc;

    const basePlayer = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    final hostLinkedPlayer = basePlayer.copyWith(
      id: 'host-slot',
      name: 'Host Player',
      firebaseId: () => 'host',
      placement: const Value(1),
    );

    final friendLinkedPlayer = basePlayer.copyWith(
      id: 'friend-slot',
      name: 'Friend Player',
      firebaseId: () => 'friend1',
      placement: const Value(2),
    );

    final unlinkedPlayer = basePlayer.copyWith(
      id: 'unlinked-slot',
      name: 'Unlinked Player',
      placement: const Value(3),
    );

    final gameModel = GameModel(
      players: const [],
      startTime: DateTime(2024),
      endTime: DateTime(2024),
      winnerId: 'host-slot',
      durationInSeconds: 60,
    );

    setUp(() {
      appBloc = MockAppBloc();
      gameBloc = MockGameBloc();
      timerBloc = MockTimerBloc();
      playerRepository = PlayerRepository();

      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'host')),
      );
      when(() => gameBloc.state).thenReturn(
        GameState(gameModel: gameModel),
      );
      when(() => timerBloc.state).thenReturn(
        const TimerState(elapsedSeconds: 60),
      );

      gameOverBloc = GameOverBloc(
        players: [hostLinkedPlayer, friendLinkedPlayer, unlinkedPlayer],
        currentUserId: 'host',
        firebaseDatabaseRepository: _MockFirebaseDatabaseRepository(),
      );
    });

    Future<void> pumpGameOverView(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<GameBloc>.value(value: gameBloc),
            BlocProvider<TimerBloc>.value(value: timerBloc),
            BlocProvider<GameOverBloc>.value(value: gameOverBloc),
          ],
          child: RepositoryProvider<PlayerRepository>.value(
            value: playerRepository,
            child: const GameOverView(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'account-owner dropdown excludes friend-linked player, includes '
      'unlinked/host-linked players and the not-playing option',
      (tester) async {
        await pumpGameOverView(tester);

        final accountOwnerDropdown = tester.widget<DropdownButton<String>>(
          find.descendant(
            of: find.byKey(
              const ValueKey('game_over_account_owner_dropdown'),
            ),
            matching: find.byType(DropdownButton<String>),
          ),
        );

        final itemValues = accountOwnerDropdown.items!
            .map((item) => item.value)
            .toList();

        expect(itemValues, isNot(contains(friendLinkedPlayer.id)));
        expect(itemValues, contains(unlinkedPlayer.id));
        expect(itemValues, contains(hostLinkedPlayer.id));
        expect(itemValues, contains(GameOverBloc.notPlayingId));
      },
    );

    testWidgets(
      'friend-linked standings row shows the linked badge icon',
      (tester) async {
        await pumpGameOverView(tester);

        expect(find.byIcon(Icons.link_rounded), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'account-owner dropdown preselects the host-linked slot',
      (tester) async {
        await pumpGameOverView(tester);

        final accountOwnerDropdown = tester.widget<DropdownButton<String>>(
          find.descendant(
            of: find.byKey(
              const ValueKey('game_over_account_owner_dropdown'),
            ),
            matching: find.byType(DropdownButton<String>),
          ),
        );

        expect(accountOwnerDropdown.value, hostLinkedPlayer.id);
      },
    );
  });

  group('GameOverView navigation on save', () {
    late MockAppBloc appBloc;
    late MockGameBloc gameBloc;
    late MockTimerBloc timerBloc;
    late PlayerRepository playerRepository;
    late _MockFirebaseDatabaseRepository firebaseDatabaseRepository;

    const basePlayer = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    final hostLinkedPlayer = basePlayer.copyWith(
      id: 'host-slot',
      name: 'Host Player',
      firebaseId: () => 'host',
      placement: const Value(1),
    );

    final otherPlayer = basePlayer.copyWith(
      id: 'other-slot',
      name: 'Other Player',
      placement: const Value(2),
    );

    final gameModel = GameModel(
      players: const [],
      startTime: DateTime(2024),
      endTime: DateTime(2024),
      winnerId: 'host-slot',
      durationInSeconds: 60,
    );

    setUp(() {
      appBloc = MockAppBloc();
      gameBloc = MockGameBloc();
      timerBloc = MockTimerBloc();
      playerRepository = PlayerRepository();
      firebaseDatabaseRepository = _MockFirebaseDatabaseRepository();

      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'host')),
      );
      when(() => gameBloc.state).thenReturn(
        GameState(gameModel: gameModel),
      );
      when(() => timerBloc.state).thenReturn(
        const TimerState(elapsedSeconds: 60),
      );
    });

    GameOverBloc buildGameOverBloc() => GameOverBloc(
      players: [hostLinkedPlayer, otherPlayer],
      currentUserId: 'host',
      firebaseDatabaseRepository: firebaseDatabaseRepository,
    );

    Future<void> pumpRoutedGameOverView(
      WidgetTester tester, {
      required GameOverBloc bloc,
    }) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: GameOverPage.routePath,
        routes: [
          GoRoute(
            path: GameOverPage.routePath,
            name: GameOverPage.routeName,
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider<AppBloc>.value(value: appBloc),
                BlocProvider<GameBloc>.value(value: gameBloc),
                BlocProvider<TimerBloc>.value(value: timerBloc),
                BlocProvider<GameOverBloc>.value(value: bloc),
              ],
              child: RepositoryProvider<PlayerRepository>.value(
                value: playerRepository,
                child: const GameOverView(),
              ),
            ),
          ),
          GoRoute(
            path: HomePage.routeName,
            name: HomePage.routeName,
            builder: (context, state) =>
                const Scaffold(body: Text('HOME_PAGE_STUB')),
          ),
          GoRoute(
            path: GamePage.routePath,
            name: GamePage.routeName,
            builder: (context, state) =>
                const Scaffold(body: Text('GAME_PAGE_STUB')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'tapping return-to-home only dispatches SendGameOverStatsEvent and '
      'stays on the page while status is loading (no eager navigation)',
      (tester) async {
        final saveCompleter = Completer<String>();
        when(() => firebaseDatabaseRepository.saveGameStats(any()))
            .thenAnswer((_) => saveCompleter.future);
        final bloc = buildGameOverBloc();
        addTearDown(bloc.close);

        await pumpRoutedGameOverView(tester, bloc: bloc);

        bloc.add(const UpdateFirstPlayerEvent('host-slot'));
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Return to Home'));
        await tester.pump();
        await tester.pump();

        expect(find.text('HOME_PAGE_STUB'), findsNothing);
        expect(bloc.state.status, GameOverStatus.loading);

        saveCompleter.complete('saved-id');
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'on success with home intent, listener navigates to home',
      (tester) async {
        when(() => firebaseDatabaseRepository.saveGameStats(any()))
            .thenAnswer((_) async => 'saved-id');
        final bloc = buildGameOverBloc();
        addTearDown(bloc.close);

        await pumpRoutedGameOverView(tester, bloc: bloc);

        bloc.add(const UpdateFirstPlayerEvent('host-slot'));
        await tester.pump();
        await tester.pump();
        await tester.tap(find.text('Return to Home'));
        await tester.pumpAndSettle();

        expect(find.text('HOME_PAGE_STUB'), findsOneWidget);
      },
    );

    testWidgets(
      'on success with playAgain intent, listener navigates to game page '
      'and dispatches GameReset/Timer events',
      (tester) async {
        when(() => firebaseDatabaseRepository.saveGameStats(any()))
            .thenAnswer((_) async => 'saved-id');
        final bloc = buildGameOverBloc();
        addTearDown(bloc.close);

        await pumpRoutedGameOverView(tester, bloc: bloc);

        bloc.add(const UpdateFirstPlayerEvent('host-slot'));
        await tester.pump();
        await tester.pump();
        await tester.tap(find.text('Play Again'));
        await tester.pumpAndSettle();

        expect(find.text('GAME_PAGE_STUB'), findsOneWidget);
        verify(() => gameBloc.add(const GameResetEvent())).called(1);
        verify(() => timerBloc.add(const TimerResetEvent())).called(1);
        verify(() => timerBloc.add(const TimerStartEvent())).called(1);
      },
    );

    testWidgets(
      'on failure, listener shows a snackbar, re-enables the buttons, and '
      'does not navigate or reset the game',
      (tester) async {
        when(() => firebaseDatabaseRepository.saveGameStats(any()))
            .thenThrow(Exception('network error'));
        final bloc = buildGameOverBloc();
        addTearDown(bloc.close);

        await pumpRoutedGameOverView(tester, bloc: bloc);

        bloc.add(const UpdateFirstPlayerEvent('host-slot'));
        await tester.pump();
        await tester.pump();
        await tester.tap(find.text('Return to Home'));
        await tester.pump();
        await tester.pump();

        expect(find.text('HOME_PAGE_STUB'), findsNothing);
        expect(find.text('GAME_PAGE_STUB'), findsNothing);
        verifyNever(() => gameBloc.add(const GameResetEvent()));
        verifyNever(() => gameBloc.add(const GameRestoreRequested()));

        final l10n = await AppLocalizations.delegate.load(const Locale('en'));
        expect(find.text(l10n.gameSaveFailedError), findsOneWidget);

        // Buttons re-enabled after failure.
        final returnButton = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.text('Return to Home'),
            matching: find.byType(OutlinedButton),
          ),
        );
        expect(returnButton.onPressed, isNotNull);
      },
    );
  });
}
