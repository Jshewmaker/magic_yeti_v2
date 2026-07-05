import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/view/game_over_page.dart';
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

void main() {
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
      tester.view.physicalSize = const Size(2600, 2400);
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

        final dropdownFinder = find.byType(DropdownButton<String>);
        // First dropdown is "who went first"; second is account owner.
        final accountOwnerDropdown = tester
            .widgetList<DropdownButton<String>>(dropdownFinder)
            .last;

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

        final dropdownFinder = find.byType(DropdownButton<String>);
        final accountOwnerDropdown = tester
            .widgetList<DropdownButton<String>>(dropdownFinder)
            .last;

        expect(accountOwnerDropdown.value, hostLinkedPlayer.id);
      },
    );
  });
}
