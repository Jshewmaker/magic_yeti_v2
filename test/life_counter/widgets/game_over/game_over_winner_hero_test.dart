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

Commander _testCommander({String name = 'Korvold, Fae-Cursed King'}) {
  return Commander(
    name: name,
    imageUrl: 'https://example.com/commander.jpg',
    colors: const [],
    cardType: 'Legendary Creature',
    manaCost: '{2}{B}{R}{G}',
    oracleText: 'Test oracle text',
    artist: 'Test Artist',
  );
}

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
      double textScale = 1,
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
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(textScale),
                ),
                child: GameOverWinnerHero(
                  winner: winner ?? base,
                  compact: compact,
                ),
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

    // Regression: a wrapped (2-line) winner name combined with a commander
    // subtitle is the ordinary case for a finished Commander game, not an
    // edge case. A numerically-tuned fixed height missed this because the
    // long-name test above uses a winner with no commander set.
    testWidgets(
      'compact does not overflow when a wrapped name meets a commander '
      'subtitle',
      (tester) async {
        await pumpHero(
          tester,
          compact: true,
          size: const Size(390, 844),
          winner: base.copyWith(
            name: 'Alexandra Fitzgerald Thompson',
            commander: _testCommander(),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'compact does not overflow with a wrapped name and a long commander '
      'name',
      (tester) async {
        await pumpHero(
          tester,
          compact: true,
          size: const Size(390, 844),
          winner: base.copyWith(
            name: 'Alexandra Fitzgerald Thompson',
            commander: _testCommander(
              name:
                  'Tiamat, the Skies’ Fury, Terror of the Five-Headed '
                  'Dragon',
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'compact does not overflow at a larger text scale with a wrapped '
      'name and a commander',
      (tester) async {
        await pumpHero(
          tester,
          compact: true,
          size: const Size(390, 844),
          winner: base.copyWith(
            name: 'Alexandra Fitzgerald Thompson',
            commander: _testCommander(),
          ),
          textScale: 1.5,
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'compact does not overflow at 2x text scale with a wrapped name and '
      'a long commander name',
      (tester) async {
        await pumpHero(
          tester,
          compact: true,
          size: const Size(390, 844),
          winner: base.copyWith(
            name: 'Alexandra Fitzgerald Thompson',
            commander: _testCommander(
              name:
                  'Tiamat, the Skies’ Fury, Terror of the Five-Headed '
                  'Dragon',
            ),
          ),
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
      },
    );

    // The tablet commander-name bound (maxLines: 1 + overflow: ellipsis) was
    // a delta beyond the brief's two enumerated changes to `_WideContent`.
    // It's a deliberate, kept fix (prevents a long commander name from
    // overflowing the fixed-200pt tablet frame) but was previously untested
    // — nothing in the suite ever rendered a tablet winner with a commander
    // set. This makes it a documented, asserted behavior instead of a silent
    // one.
    testWidgets(
      'non-compact ellipsizes a long commander name to one line',
      (tester) async {
        const longCommanderName =
            'Tiamat, the Skies’ Fury, Terror of the Five-Headed Dragon';
        await pumpHero(
          tester,
          compact: false,
          size: const Size(1280, 800),
          winner: base.copyWith(
            commander: _testCommander(name: longCommanderName),
          ),
        );

        expect(tester.takeException(), isNull);

        final commanderText = tester.widget<Text>(
          find.text(longCommanderName),
        );
        expect(commanderText.maxLines, 1);
        expect(commanderText.overflow, TextOverflow.ellipsis);
      },
    );

    // Confirms the tablet path — still a fixed 200pt frame, unlike the
    // compact path which now grows — has no overflow even when both the
    // winner name and the commander name are long simultaneously.
    testWidgets(
      'non-compact does not overflow with a long winner name and a long '
      'commander name',
      (tester) async {
        const longName = 'Bartholomew Maximilian Featherstonehaugh The Third';
        const longCommanderName =
            'Tiamat, the Skies’ Fury, Terror of the Five-Headed Dragon';
        await pumpHero(
          tester,
          compact: false,
          size: const Size(1280, 800),
          winner: base.copyWith(
            name: longName,
            commander: _testCommander(name: longCommanderName),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );
  });
}
