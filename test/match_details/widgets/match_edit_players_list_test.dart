// test/match_details/widgets/match_edit_players_list_test.dart
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';
import 'package:magic_yeti/match_details/widgets/match_edit_players_list.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../helpers/helpers.dart';

class _MockDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

const _picked = Commander(
  name: 'Krenko',
  colors: ['R'],
  cardType: 'Legendary Creature',
  imageUrl: '',
  manaCost: '',
  oracleText: '',
  artist: '',
);

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
    )..startEditing(_game());
  });

  testWidgets('renders a tile per draft player', (tester) async {
    await tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: SingleChildScrollView(
          child: MatchEditPlayersList(
            pickCommander: (_, {required bool selectingPartner}) async => null,
          ),
        ),
      ),
    );
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('selecting a commander from the picker updates the draft',
      (tester) async {
    await tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: SingleChildScrollView(
          child: MatchEditPlayersList(
            pickCommander: (_, {required bool selectingPartner}) async =>
                _picked,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('edit-commander-p1')));
    await tester.pumpAndSettle();

    expect(cubit.state.draftPlayers.first.commander, _picked);
  });
}
