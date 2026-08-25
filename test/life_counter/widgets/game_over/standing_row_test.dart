import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:player_repository/player_repository.dart';

import '../../../helpers/pump_app.dart';

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
                onReorder: (_, __) {},
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
}
