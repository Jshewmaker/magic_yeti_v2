import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:magic_yeti/tracker/tracker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class _MockGameBloc extends MockBloc<GameEvent, GameState>
    implements GameBloc {}

class _MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

List<Player> _players(int count) {
  final ids = [for (var i = 0; i < count; i++) 'p$i'];
  return [
    for (final id in ids)
      Player(
        id: id,
        name: id,
        playerNumber: 0,
        lifePoints: 20,
        color: 0xFF378ADD,
        state: PlayerModelState.active,
        opponents: [
          for (final opponentId in ids)
            Opponent(
              playerId: opponentId,
              damages: [
                CommanderDamage(damageType: DamageType.commander, amount: 0),
                CommanderDamage(damageType: DamageType.partner, amount: 0),
              ],
            ),
        ],
      ),
  ];
}

void main() {
  late _MockGameBloc gameBloc;
  late _MockPlayerBloc playerBloc;

  setUp(() {
    gameBloc = _MockGameBloc();
    playerBloc = _MockPlayerBloc();
  });

  Future<void> pumpTrackers(WidgetTester tester, List<Player> players) async {
    when(() => playerBloc.state).thenReturn(PlayerState(player: players[0]));
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceInfoProvider(
          isPhone: true,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<GameBloc>.value(value: gameBloc),
              BlocProvider<PlayerBloc>.value(value: playerBloc),
            ],
            child: Scaffold(
              body: SizedBox(
                height: 120,
                child: TrackerWidgets(
                  rotate: true,
                  playerId: players[0].id,
                  leftSideTracker: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> addPoisonTracker(WidgetTester tester) async {
    await tester.tap(find.byType(IconButton).last);
    await tester.pumpAndSettle();
    final poisonCell = find
        .ancestor(of: find.text('Poison'), matching: find.byType(Column))
        .first;
    await tester.tap(
      find.descendant(of: poisonCell, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();
  }

  group('TrackerWidgets', () {
    testWidgets('shows no commander damage in a two-player game', (
      tester,
    ) async {
      final players = _players(2);
      when(() => gameBloc.state).thenReturn(
        GameState(status: GameStatus.running, playerList: players),
      );

      await pumpTrackers(tester, players);

      expect(find.byType(CommanderDamageTracker), findsNothing);
    });

    testWidgets('shows commander damage for each player in a four-player '
        'game', (tester) async {
      final players = _players(4);
      when(() => gameBloc.state).thenReturn(
        GameState(status: GameStatus.running, playerList: players),
      );

      await pumpTrackers(tester, players);

      expect(find.byType(CommanderDamageTracker), findsNWidgets(4));
    });

    testWidgets('clears added counters when the game is reset', (
      tester,
    ) async {
      final players = _players(2);
      final running = GameState(
        status: GameStatus.running,
        playerList: players,
      );
      final controller = StreamController<GameState>();
      addTearDown(controller.close);
      whenListen(gameBloc, controller.stream, initialState: running);

      await pumpTrackers(tester, players);
      await addPoisonTracker(tester);

      expect(find.byType(CounterTrackerWidget), findsOneWidget);
      await tester.tap(find.byType(CounterTrackerWidget));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      controller.add(running.copyWith(status: GameStatus.reset));
      await tester.pump();
      await tester.pump();

      expect(find.byType(CounterTrackerWidget), findsNothing);
    });
  });
}
