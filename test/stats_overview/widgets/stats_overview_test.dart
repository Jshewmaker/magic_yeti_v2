import 'package:app_ui/app_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game_tags/game_tags.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:user_repository/user_repository.dart';

import '../../helpers/helpers.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockMatchHistoryBloc
    extends MockBloc<MatchHistoryEvent, MatchHistoryState>
    implements MatchHistoryBloc {}

class _MockScryfallRepository extends Mock implements ScryfallRepository {}

GameModel _game(String id, {List<String> tags = const []}) => GameModel(
  id: id,
  players: const [
    Player(
      id: 'p1',
      name: 'Player 1',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
      firebaseId: 'alice',
    ),
  ],
  startTime: DateTime(2020),
  endTime: DateTime(2020, 1, 1, 1),
  winnerId: 'p1',
  durationInSeconds: 3600,
  tags: tags,
);

void main() {
  late _MockAppBloc appBloc;
  late _MockMatchHistoryBloc matchHistoryBloc;

  setUp(() {
    appBloc = _MockAppBloc();
    matchHistoryBloc = _MockMatchHistoryBloc();
    when(
      () => appBloc.state,
    ).thenReturn(const AppState.authenticated(User(id: 'alice')));
  });

  Future<void> pumpStats(WidgetTester tester, List<GameModel> games) async {
    when(() => matchHistoryBloc.state).thenReturn(
      MatchHistoryState(
        status: MatchHistoryStatus.loadingHistorySuccess,
        games: games,
      ),
    );
    await tester.pumpApp(
      DeviceInfoProvider(
        isPhone: true,
        child: RepositoryProvider<ScryfallRepository>.value(
          value: _MockScryfallRepository(),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AppBloc>.value(value: appBloc),
              BlocProvider<MatchHistoryBloc>.value(value: matchHistoryBloc),
            ],
            child: const Scaffold(body: StatsOverviewWidget()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hides the tag filter when no game has a tag', (tester) async {
    await pumpStats(tester, [_game('a'), _game('b')]);

    expect(find.byKey(const Key('stats_tag_filter')), findsNothing);
  });

  testWidgets('choosing a tag limits the stats to the tagged games', (
    tester,
  ) async {
    await pumpStats(tester, [
      _game('a', tags: const ['bracket_3']),
      _game('b'),
      _game('c'),
    ]);

    // Total games and total wins across every game.
    expect(find.text('3'), findsWidgets);

    await tester.tap(find.byKey(const Key('stats_tag_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bracket 3').last);
    await tester.pumpAndSettle();

    final selected = tester
        .widget<DropdownButton<GameTag?>>(
          find.byKey(const Key('stats_tag_filter')),
        )
        .value;
    expect(selected, GameTag.bracket3);
    // Total games and total wins both drop from 3 to 1.
    expect(find.text('3'), findsNothing);
  });
}
