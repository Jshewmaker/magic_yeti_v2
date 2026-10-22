import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/widgets/match_history_list_item.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:user_repository/user_repository.dart';

import '../../helpers/helpers.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

Player _seat(String id, {required int placement, String? commander}) =>
    Player(
      id: id,
      name: 'Name-$id',
      playerNumber: 0,
      lifePoints: 40,
      color: 0xFF000000,
      opponents: const [],
      placement: placement,
      firebaseId: id,
      commander: commander == null
          ? null
          : Commander(
              name: commander,
              colors: const ['G'],
              cardType: 'Legendary Creature',
              imageUrl: '',
              manaCost: '{G}',
              oracleText: '',
              artist: 'A',
            ),
    );

void main() {
  group('MatchHistoryListItem', () {
    late AppBloc appBloc;

    setUp(() {
      appBloc = _MockAppBloc();
      when(
        () => appBloc.state,
      ).thenReturn(const AppState.authenticated(User(id: 'me')));
    });

    testWidgets(
      'keeps the date inside the card when the commander name is long',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.6;
        addTearDown(tester.view.reset);

        final game = GameModel(
          id: 'game',
          roomId: 'ABCD',
          winnerId: 'winner',
          startTime: DateTime(2026, 10, 8, 12),
          endTime: DateTime(2026, 10, 8, 13, 17),
          durationInSeconds: 4620,
          players: [
            _seat(
              'winner',
              placement: 1,
              commander: 'Tetzin, Gnome Champion // The Golden-Gear Colossus',
            ),
            _seat('second', placement: 2),
          ],
        );

        await tester.pumpApp(
          BlocProvider.value(
            value: appBloc,
            child: Scaffold(body: MatchHistoryListItem(game: game)),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('10/8/2026'), findsOneWidget);
      },
    );
  });
}
