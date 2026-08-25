import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../../helpers/pump_app.dart';

class _MockGameOverBloc extends MockBloc<GameOverEvent, GameOverState>
    implements GameOverBloc {}

void main() {
  group('GameOverDetailsFields', () {
    late _MockGameOverBloc bloc;

    const base = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    final players = [
      base.copyWith(id: 'a', name: 'Alice', placement: const Value(1)),
      base.copyWith(id: 'b', name: 'Bob', placement: const Value(2)),
    ];

    late GameOverState state;

    setUp(() {
      bloc = _MockGameOverBloc();
      state = GameOverState(
        standings: players,
        selectedPlayerId: null,
        firstPlayerId: null,
      );
      when(() => bloc.state).thenReturn(state);
    });

    Future<void> pumpFields(
      WidgetTester tester, {
      required bool compact,
    }) async {
      tester.view.physicalSize =
          compact ? const Size(390, 844) : const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        BlocProvider<GameOverBloc>.value(
          value: bloc,
          child: Scaffold(
            body: SingleChildScrollView(
              child: GameOverDetailsFields(
                state: state,
                players: players,
                currentUserId: 'host',
                compact: compact,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders both dropdowns at phone width without overflow',
        (tester) async {
      await pumpFields(tester, compact: true);

      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('game_over_account_owner_dropdown')),
        findsOneWidget,
      );
    });

    testWidgets('compact uses the short account owner label', (tester) async {
      await pumpFields(tester, compact: true);

      expect(find.text('Account Owner'), findsOneWidget);
    });

    testWidgets('non-compact keeps the full account owner sentence',
        (tester) async {
      await pumpFields(tester, compact: false);

      expect(find.text('Account Owner'), findsNothing);
      expect(
        find.textContaining('Please select the account owner'),
        findsOneWidget,
      );
    });

    testWidgets('picking a first player dispatches UpdateFirstPlayerEvent',
        (tester) async {
      await pumpFields(tester, compact: true);

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();

      verify(() => bloc.add(const UpdateFirstPlayerEvent('a'))).called(1);
    });

    testWidgets('picking an account owner dispatches UpdateSelectedPlayerEvent',
        (tester) async {
      await pumpFields(tester, compact: true);

      await tester.tap(
        find.byKey(const ValueKey('game_over_account_owner_dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').last);
      await tester.pumpAndSettle();

      verify(() => bloc.add(const UpdateSelectedPlayerEvent('b'))).called(1);
    });
  });
}
