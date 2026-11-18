import 'package:app_ui/app_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/life_counter.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:magic_yeti/tracker/tracker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../helpers/pump_app.dart';

class _MockGameBloc extends MockBloc<GameEvent, GameState>
    implements GameBloc {}

class _MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

Player _player(String id, String otherId) => Player(
  id: id,
  name: 'Player $id',
  playerNumber: 0,
  lifePoints: 20,
  color: 0xFF378ADD,
  state: PlayerModelState.active,
  opponents: [
    for (final opponentId in [id, otherId])
      Opponent(
        playerId: opponentId,
        damages: [
          CommanderDamage(damageType: DamageType.commander, amount: 0),
          CommanderDamage(damageType: DamageType.partner, amount: 0),
        ],
      ),
  ],
);

void main() {
  late PlayerRepository playerRepository;
  late _MockGameBloc gameBloc;
  late _MockTimerBloc timerBloc;

  setUp(() {
    playerRepository = PlayerRepository()
      ..createPlayer(_player('a', 'b'))
      ..createPlayer(_player('b', 'a'));
    gameBloc = _MockGameBloc();
    timerBloc = _MockTimerBloc();
    when(() => gameBloc.state).thenReturn(
      GameState(
        status: GameStatus.running,
        playerList: playerRepository.getPlayers(),
      ),
    );
    when(() => timerBloc.state).thenReturn(
      const TimerState(status: TimerStatus.running),
    );
  });

  Future<void> pumpGame(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpApp(
      DeviceInfoProvider(
        isPhone: true,
        child: RepositoryProvider.value(
          value: playerRepository,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<GameBloc>.value(value: gameBloc),
              BlocProvider<TimerBloc>.value(value: timerBloc),
            ],
            child: const TwoPlayerGame(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('TwoPlayerGame', () {
    for (final size in const [Size(320, 568), Size(375, 667), Size(390, 844)]) {
      testWidgets('lays out without overflow at ${size.width}x${size.height}', (
        tester,
      ) async {
        await pumpGame(tester, size);

        expect(find.byType(PlayerTile), findsNWidgets(2));
        expect(find.text('20'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('runs the player areas to the top and bottom screen edges', (
      tester,
    ) async {
      await pumpGame(tester, const Size(375, 667));

      expect(tester.getRect(find.byType(PlayerTile).first).top, 0);
      expect(tester.getRect(find.byType(PlayerTile).last).bottom, 667);
    });

    testWidgets('shows the controls as a bar, without the collapse button', (
      tester,
    ) async {
      await pumpGame(tester, const Size(375, 667));

      final bar = tester.getSize(find.byType(CenterControlColumn));
      expect(bar.width, greaterThan(bar.height));
      expect(find.byIcon(Icons.close_fullscreen), findsNothing);
      expect(find.byIcon(Icons.home_filled), findsOneWidget);
    });

    testWidgets('sizes the life total to the half-screen tile', (tester) async {
      await pumpGame(tester, const Size(375, 667));

      final life = tester.widget<StrokeText>(
        find.widgetWithText(StrokeText, '20').first,
      );
      expect(life.fontSize, greaterThan(48));
    });

    testWidgets("tapping plus raises that player's life", (tester) async {
      await pumpGame(tester, const Size(375, 667));

      await tester.tap(
        find.byKey(const ValueKey('life_counter_widget_increment')).last,
      );
      await tester.pumpAndSettle();

      expect(playerRepository.getPlayerById('a').lifePoints, 21);
      expect(playerRepository.getPlayerById('b').lifePoints, 20);
    });

    testWidgets('opens a tracker drawer with no commander damage', (
      tester,
    ) async {
      await pumpGame(tester, const Size(375, 667));

      await tester.tap(find.byIcon(Icons.keyboard_arrow_up).last);
      await tester.pumpAndSettle();

      expect(find.byType(TrackerWidgets), findsNWidgets(2));
      expect(find.byType(CommanderDamageTracker), findsNothing);
    });
  });
}
