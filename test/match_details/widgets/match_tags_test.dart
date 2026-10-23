import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';
import 'package:magic_yeti/match_details/widgets/match_edit_players_list.dart';
import 'package:magic_yeti/match_details/widgets/match_tags.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../helpers/helpers.dart';

class _MockDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

Player _player(String id, String name, {List<String> tags = const []}) =>
    Player(
      id: id,
      name: name,
      playerNumber: 1,
      lifePoints: 40,
      color: 0xFF000000,
      opponents: const [],
      placement: 1,
      timeOfDeath: 0,
      tags: tags,
    );

GameModel _game({
  List<String> tags = const [],
  List<String> aliceTags = const [],
}) => GameModel(
  id: 'g1',
  players: [
    _player('p1', 'Alice', tags: aliceTags),
    _player('p2', 'Bob'),
  ],
  startTime: DateTime(2026),
  endTime: DateTime(2026, 1, 1, 1),
  winnerId: 'p1',
  durationInSeconds: 10,
  tags: tags,
);

void main() {
  group('MatchTagsWidget', () {
    testWidgets('shows a placeholder when the game has no tags', (
      tester,
    ) async {
      await tester.pumpApp(Scaffold(body: MatchTagsWidget(game: _game())));

      expect(find.text('No tags'), findsOneWidget);
    });

    testWidgets('shows the game tags and each tagged player', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: MatchTagsWidget(
            game: _game(
              tags: const ['bracket_3', 'from_a_newer_app'],
              aliceTags: const ['t1_sol_ring'],
            ),
          ),
        ),
      );

      expect(find.text('No tags'), findsNothing);
      expect(find.text('Bracket 3'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Turn 1 Sol Ring'), findsOneWidget);
      // Bob has no tags, so he gets no heading.
      expect(find.text('Bob'), findsNothing);
    });
  });

  group('edit mode', () {
    late MatchEditCubit cubit;

    setUp(() {
      cubit = MatchEditCubit(
        databaseRepository: _MockDatabaseRepository(),
        currentUserId: 'u1',
      )..startEditing(_game(tags: const ['bracket_1']));
    });

    tearDown(() => cubit.close());

    testWidgets('MatchEditGameTags toggles a game tag', (tester) async {
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: SingleChildScrollView(child: MatchEditGameTags()),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tag_pill_bracket_2')));
      await tester.pump();

      expect(cubit.state.draftGameTags, ['bracket_2']);
    });

    testWidgets('the tile tag button opens the sheet and tags the player', (
      tester,
    ) async {
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: SingleChildScrollView(
              child: MatchEditPlayersList(
                pickCommander: (_, {required selectingPartner}) async => null,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('edit-tags-p2')));
      await tester.pumpAndSettle();
      expect(find.text('Tags for Bob'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tag_pill_clutch_topdeck')));
      await tester.pump();
      expect(cubit.state.draftPlayers[1].tags, ['clutch_topdeck']);

      await tester.tap(find.byKey(const Key('player_tags_sheet_done')));
      await tester.pumpAndSettle();

      // The tile now lists the new tag.
      expect(find.text('Clutch topdeck'), findsOneWidget);
    });
  });
}
