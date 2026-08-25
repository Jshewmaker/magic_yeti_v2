import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../../helpers/pump_app.dart';

class _MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

void main() {
  group('GameOverWinnerHero', () {
    late _MockTimerBloc timerBloc;

    const base = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    setUp(() {
      timerBloc = _MockTimerBloc();
      when(() => timerBloc.state).thenReturn(
        const TimerState(elapsedSeconds: 3600 + 23 * 60),
      );
    });

    Future<void> pumpHero(
      WidgetTester tester, {
      required bool compact,
      required Size size,
      Player? winner,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        BlocProvider<TimerBloc>.value(
          value: timerBloc,
          child: Scaffold(
            body: SingleChildScrollView(
              child: GameOverWinnerHero(
                winner: winner ?? base,
                compact: compact,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('compact renders at phone width without overflow', (
      tester,
    ) async {
      await pumpHero(tester, compact: true, size: const Size(390, 844));

      expect(tester.takeException(), isNull);
      expect(find.text('1h 23m'), findsOneWidget);
    });

    testWidgets('compact ellipsizes a long winner name over two lines', (
      tester,
    ) async {
      const longName = 'Bartholomew Maximilian Featherstonehaugh The Third';
      await pumpHero(
        tester,
        compact: true,
        size: const Size(390, 844),
        winner: base.copyWith(name: longName),
      );

      expect(tester.takeException(), isNull);

      final nameText = tester.widget<Text>(find.text(longName));
      expect(nameText.maxLines, 2);
      expect(nameText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('non-compact keeps the boxed duration chip', (tester) async {
      await pumpHero(tester, compact: false, size: const Size(1280, 800));

      expect(tester.takeException(), isNull);
      expect(find.text('1h 23m'), findsOneWidget);
    });
  });
}
