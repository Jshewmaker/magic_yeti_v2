import 'dart:io';

import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../../helpers/pump_app.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  group('GameOverStandingsPanel reorder (Fix 3)', () {
    const base = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    List<Player> fourPlayers() => [
      base.copyWith(
        id: 'slot-1',
        name: 'First Player',
        placement: const Value(1),
      ),
      base.copyWith(
        id: 'slot-2',
        name: 'Second Player',
        placement: const Value(2),
      ),
      base.copyWith(
        id: 'slot-3',
        name: 'Third Player',
        placement: const Value(3),
      ),
      base.copyWith(
        id: 'slot-4',
        name: 'Fourth Player',
        placement: const Value(4),
      ),
    ];

    Future<GameOverBloc> pumpPanel(WidgetTester tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Built inline, not via setUp/late: a real GameOverBloc's internal
      // event-stream subscription binds to whatever zone is active at
      // construction time, and setUp() runs outside the zone flutter_test
      // wraps the testWidgets body in — a bloc built there silently stops
      // notifying BlocBuilder even though bloc.state itself updates fine.
      final bloc = GameOverBloc(
        players: fourPlayers(),
        currentUserId: 'nobody',
        firebaseDatabaseRepository: _MockFirebaseDatabaseRepository(),
      );
      addTearDown(bloc.close);

      await tester.pumpApp(
        BlocProvider<GameOverBloc>.value(
          value: bloc,
          child: Scaffold(
            body: BlocBuilder<GameOverBloc, GameOverState>(
              builder: (context, state) => GameOverStandingsPanel(state: state),
            ),
          ),
        ),
      );
      await tester.pump();
      return bloc;
    }

    testWidgets(
      'dragging the first row to the end reorders via the shared '
      'onStandingsReorder — raw indices, no double adjustment',
      (tester) async {
        // Mirrors the phone's equivalent regression test. The two
        // reorderable widgets (SliverReorderableList on the phone,
        // ReorderableListView here) share the same oldIndex/newIndex
        // convention, and GameOverBloc._onUpdateStandings already does the
        // newIndex-1 adjustment for a forward move. Extracting
        // onStandingsReorder (Fix 3) must not add a second adjustment — if
        // it did, this drag would land one slot short of the end.
        final bloc = await pumpPanel(tester);

        final firstGrip = find.byType(ReorderableDragStartListener).first;
        final gesture = await tester.startGesture(
          tester.getCenter(firstGrip),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump();
        await gesture.moveBy(const Offset(0, 220));
        await tester.pumpAndSettle();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(
          bloc.state.standings.map((p) => p.id).toList(),
          ['slot-2', 'slot-3', 'slot-4', 'slot-1'],
        );
      },
    );
  });

  group('StandingRow placement label layout', () {
    // flutter test falls back to the Ahem placeholder font unless a real
    // font is registered — see
    // packages/app_ui/test/src/typography/app_ui_text_style_test.dart for
    // the same pattern. Ahem renders every glyph as a fixed `fontSize`
    // square, so "1ST"/"2ND"/"3RD"/"4TH" (all 3 characters) would measure
    // identically and this test would never see the bug it exists to catch:
    // in the app's real font, "2ND" happens to be a hair wider than the
    // other three labels, which is exactly why only "2ND" wrapped.
    const family = 'StandingRowPlacementTestFont';

    late double singleLineHeight;

    setUpAll(() async {
      final loader = FontLoader(family);
      final bytes = File(
        'packages/app_ui/assets/fonts/NunitoSans-Bold.ttf',
      ).readAsBytesSync();
      loader.addFont(
        Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
      );
      await loader.load();

      // A single, unambiguously-one-line glyph measured under the same
      // style, used below as the "not wrapped" reference instead of a
      // hardcoded pixel height that would silently go stale if the label's
      // font/size/weight ever changed.
      final painter = TextPainter(
        text: const TextSpan(
          text: '1',
          style: TextStyle(
            fontFamily: family,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      singleLineHeight = painter.height;
    });

    const base = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    Future<void> pumpRow(WidgetTester tester, int placement) async {
      await tester.pumpApp(
        Scaffold(
          body: DefaultTextStyle(
            style: const TextStyle(fontFamily: family),
            child: StandingRow(
              player: base.copyWith(name: 'Standing Player $placement'),
              placement: placement,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    for (final placement in [1, 2, 3, 4]) {
      final label = GameOverTokens.placementLabel(placement);

      testWidgets(
        '$label renders on a single line with a clear gap before the name',
        (tester) async {
          await pumpRow(tester, placement);

          final labelRect = tester.getRect(find.text(label));
          final nameRect = tester.getRect(
            find.text('Standing Player $placement'),
          );

          // A wrapped label ("2N" over "D") is roughly double a single
          // line's height — this is what catches "2ND" wrapping when the
          // fixed box was too narrow for it.
          expect(
            labelRect.height,
            closeTo(singleLineHeight, 2),
            reason: 'Placement label "$label" wrapped onto multiple lines',
          );

          // The old fixed-width box put the name flush against the label's
          // right edge whenever the label's ink nearly filled the box —
          // this is what catches "3RD"/"4TH" touching the player name with
          // no visible gap.
          expect(
            nameRect.left - labelRect.right,
            greaterThan(4),
            reason: 'Placement label "$label" has no gap before the name',
          );
        },
      );
    }
  });
}
