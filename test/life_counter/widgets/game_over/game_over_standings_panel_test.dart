import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
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
              builder: (context, state) =>
                  GameOverStandingsPanel(state: state),
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
}
