import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';
import 'package:magic_yeti/match_details/widgets/match_details_app_bar_actions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../helpers/helpers.dart';

class _MockDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

GameModel _game() => GameModel(
      id: 'g1',
      players: [
        Player(
          id: 'p1',
          name: 'Alice',
          playerNumber: 1,
          lifePoints: 40,
          color: 0xFF000000,
          opponents: const [],
          state: PlayerModelState.eliminated,
          placement: 1,
          timeOfDeath: 0,
        ),
      ],
      startTime: DateTime(2026),
      endTime: DateTime(2026, 1, 1, 1),
      winnerId: 'p1',
      durationInSeconds: 10,
    );

void main() {
  late MatchEditCubit cubit;

  setUp(() {
    cubit = MatchEditCubit(
      databaseRepository: _MockDatabaseRepository(),
      currentUserId: 'u1',
    );
  });

  Widget subject() => BlocProvider.value(
        value: cubit,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              MatchDetailsAppBarActions(
                game: _game(),
                deleteAction: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      );

  testWidgets('shows edit + delete when viewing', (tester) async {
    await tester.pumpApp(subject());
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('tapping edit enters editing and shows save/cancel',
      (tester) async {
    await tester.pumpApp(subject());
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    expect(cubit.state.isEditing, isTrue);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('tapping cancel returns to viewing', (tester) async {
    await tester.pumpApp(subject());
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(cubit.state.isEditing, isFalse);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });
}
