import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/gestures.dart';
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
  group('StandingRow', () {
    const base = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    Future<void> pumpRow(
      WidgetTester tester,
      Player player, {
      int? dragIndex,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverReorderableList(
                itemCount: 1,
                onReorder: (_, _) {},
                itemBuilder: (context, index) => StandingRow(
                  key: ValueKey(player.id),
                  player: player,
                  placement: 1,
                  dragIndex: dragIndex,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a very long player name ellipsizes instead of overflowing', (
      tester,
    ) async {
      await pumpRow(
        tester,
        base.copyWith(
          name: 'Bartholomew Maximilian Featherstonehaugh The Third',
        ),
        dragIndex: 0,
      );

      expect(tester.takeException(), isNull);

      final nameText = tester.widget<Text>(
        find.text('Bartholomew Maximilian Featherstonehaugh The Third'),
      );
      expect(nameText.overflow, TextOverflow.ellipsis);
      expect(nameText.maxLines, 1);
    });

    testWidgets('exposes a drag listener when dragIndex is provided', (
      tester,
    ) async {
      await pumpRow(tester, base, dragIndex: 0);

      expect(find.byType(ReorderableDragStartListener), findsOneWidget);
    });

    testWidgets('has no drag listener when dragIndex is null', (tester) async {
      await pumpRow(tester, base);

      expect(find.byType(ReorderableDragStartListener), findsNothing);
      expect(find.byIcon(Icons.drag_handle_rounded), findsOneWidget);
    });
  });

  group('GameOverStandingsPanel drag exclusivity', () {
    const basePlayer = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    final playerA = basePlayer.copyWith(id: 'a', name: 'Player A');
    final playerB = basePlayer.copyWith(
      id: 'b',
      name: 'Player B',
      placement: const Value(2),
    );
    final playerC = basePlayer.copyWith(
      id: 'c',
      name: 'Player C',
      placement: const Value(3),
    );

    GameOverBloc buildBloc() => GameOverBloc(
      players: [playerA, playerB, playerC],
      currentUserId: 'nobody',
      firebaseDatabaseRepository: _MockFirebaseDatabaseRepository(),
    );

    Future<void> pumpPanel(WidgetTester tester, GameOverBloc bloc) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        BlocProvider<GameOverBloc>.value(
          value: bloc,
          child: Scaffold(body: GameOverStandingsPanel(state: bloc.state)),
        ),
      );
      await tester.pump();
    }

    testWidgets('dragging the grip reorders the standings', (tester) async {
      final bloc = buildBloc();
      addTearDown(bloc.close);
      await pumpPanel(tester, bloc);

      final grip = tester.getCenter(
        find.descendant(
          of: find.byKey(ValueKey(playerA.id)),
          matching: find.byIcon(Icons.drag_handle_rounded),
        ),
      );

      // ReorderableDragStartListener starts immediately on pointer-down +
      // movement past touch slop — no long-press wait needed.
      final drag = await tester.startGesture(grip);
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 300));
      await tester.pumpAndSettle();
      await drag.up();
      await tester.pumpAndSettle();

      expect(
        bloc.state.standings.map((player) => player.id).toList(),
        [playerB.id, playerC.id, playerA.id],
      );
    });

    testWidgets(
      'dragging the row body (away from the grip) does not reorder',
      (tester) async {
        final bloc = buildBloc();
        addTearDown(bloc.close);
        await pumpPanel(tester, bloc);

        final bodyPoint = tester.getCenter(find.text(playerA.name));

        // Long-press first: this is exactly what would arm the default
        // ReorderableDelayedDragStartListener if buildDefaultDragHandles
        // were ever reintroduced.
        final drag = await tester.startGesture(bodyPoint);
        await tester.pump(kLongPressTimeout + kPressTimeout);
        await drag.moveBy(const Offset(0, 300));
        await tester.pumpAndSettle();
        await drag.up();
        await tester.pumpAndSettle();

        expect(
          bloc.state.standings.map((player) => player.id).toList(),
          [playerA.id, playerB.id, playerC.id],
        );
      },
    );
  });

  group('GameOverSectionLabel', () {
    testWidgets('renders the label text', (tester) async {
      await tester.pumpApp(
        const GameOverSectionLabel(label: 'FINAL STANDINGS'),
      );

      expect(find.text('FINAL STANDINGS'), findsOneWidget);
    });

    testWidgets('renders the trailing widget when provided', (tester) async {
      await tester.pumpApp(
        const GameOverSectionLabel(
          label: 'FINAL STANDINGS',
          trailing: Icon(Icons.info),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('omits the trailing slot when not provided', (tester) async {
      await tester.pumpApp(
        const GameOverSectionLabel(label: 'FINAL STANDINGS'),
      );

      expect(find.byType(Icon), findsNothing);
    });
  });
}
