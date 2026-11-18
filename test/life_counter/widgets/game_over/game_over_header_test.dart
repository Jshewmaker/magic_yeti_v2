import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGameBloc extends MockBloc<GameEvent, GameState>
    implements GameBloc {}

class _MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

void main() {
  group('GameOverHeader', () {
    late _MockGameBloc gameBloc;
    late _MockTimerBloc timerBloc;

    setUp(() {
      gameBloc = _MockGameBloc();
      timerBloc = _MockTimerBloc();
      when(() => gameBloc.state).thenReturn(const GameState());
      when(() => timerBloc.state).thenReturn(const TimerState());
    });

    Future<void> pumpHeader(
      WidgetTester tester, {
      required Size size,
      required bool compact,
      bool canRestoreGame = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<GameBloc>.value(value: gameBloc),
            BlocProvider<TimerBloc>.value(value: timerBloc),
          ],
          child: Scaffold(
            body: GameOverHeader(
              canRestoreGame: canRestoreGame,
              compact: compact,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('does not overflow at phone width', (tester) async {
      await pumpHeader(
        tester,
        size: const Size(390, 844),
        compact: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('MATCH COMPLETE'), findsOneWidget);
    });

    testWidgets('compact hides the restore label but keeps the control', (
      tester,
    ) async {
      await pumpHeader(
        tester,
        size: const Size(390, 844),
        compact: true,
      );

      expect(find.text('RESTORE GAME'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('non-compact keeps the restore label', (tester) async {
      await pumpHeader(
        tester,
        size: const Size(1280, 800),
        compact: false,
      );

      expect(find.text('RESTORE GAME'), findsOneWidget);
    });

    testWidgets('omits the restore control when the game cannot be restored', (
      tester,
    ) async {
      await pumpHeader(
        tester,
        size: const Size(1280, 800),
        compact: false,
        canRestoreGame: false,
      );

      expect(find.text('RESTORE GAME'), findsNothing);
    });

    testWidgets(
      'spans the full width even when the restore control is absent',
      (tester) async {
        await pumpHeader(
          tester,
          size: const Size(1280, 800),
          compact: false,
          canRestoreGame: false,
        );

        expect(tester.getSize(find.byType(GameOverHeader)).width, 1280);
      },
    );

    testWidgets('compact with no restorable game renders without overflow and '
        'omits the restore control', (tester) async {
      await pumpHeader(
        tester,
        size: const Size(390, 844),
        compact: true,
        canRestoreGame: false,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('MATCH COMPLETE'), findsOneWidget);
      expect(find.text('RESTORE GAME'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
      expect(tester.getSize(find.byType(GameOverHeader)).width, 390);
    });
  });
}
