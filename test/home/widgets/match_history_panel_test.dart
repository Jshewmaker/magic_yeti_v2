import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/home/widgets/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:user_repository/user_repository.dart';

import '../../helpers/helpers.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockMatchHistoryBloc
    extends MockBloc<MatchHistoryEvent, MatchHistoryState>
    implements MatchHistoryBloc {}

GameModel _game(String roomId, int playerCount) => GameModel(
  id: roomId,
  roomId: roomId,
  winnerId: 'p1',
  startTime: DateTime(2026, 10),
  endTime: DateTime(2026, 10, 1, 1),
  durationInSeconds: 3600,
  players: [
    for (var i = 1; i <= playerCount; i++)
      Player(
        id: 'p$i',
        name: 'Player $i',
        playerNumber: i,
        lifePoints: 0,
        color: 0xFF000000,
        opponents: const [],
        placement: i,
      ),
  ],
);

void main() {
  late _MockAppBloc appBloc;
  late _MockMatchHistoryBloc matchHistoryBloc;

  final commanderGame = _game('EDH1', 4);
  final constructedGame = _game('ONE1', 2);

  setUp(() {
    appBloc = _MockAppBloc();
    matchHistoryBloc = _MockMatchHistoryBloc();
    when(
      () => appBloc.state,
    ).thenReturn(const AppState.authenticated(User(id: 'me')));
  });

  Future<void> pumpPanel(WidgetTester tester, MatchHistoryState state) {
    when(() => matchHistoryBloc.state).thenReturn(state);
    return tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppBloc>.value(value: appBloc),
          BlocProvider<MatchHistoryBloc>.value(value: matchHistoryBloc),
        ],
        child: const Scaffold(body: MatchHistoryPanel()),
      ),
    );
  }

  MatchHistoryState loaded(MatchFormatFilter filter) => MatchHistoryState(
    status: MatchHistoryStatus.loadingHistorySuccess,
    games: [commanderGame, constructedGame],
    formatFilter: filter,
  );

  group('MatchHistoryPanel format filter', () {
    testWidgets('shows every game when the filter is All games', (
      tester,
    ) async {
      await pumpPanel(tester, loaded(MatchFormatFilter.all));

      expect(find.byType(MatchHistoryListItem), findsNWidgets(2));
      expect(find.text('All games'), findsOneWidget);
    });

    testWidgets('shows only constructed games', (tester) async {
      await pumpPanel(tester, loaded(MatchFormatFilter.constructed));

      final item = tester.widget<MatchHistoryListItem>(
        find.byType(MatchHistoryListItem),
      );
      expect(item.game, constructedGame);
    });

    testWidgets('says so when no game matches the filter', (tester) async {
      await pumpPanel(
        tester,
        MatchHistoryState(
          status: MatchHistoryStatus.loadingHistorySuccess,
          games: [commanderGame],
          formatFilter: MatchFormatFilter.constructed,
        ),
      );

      expect(find.byType(MatchHistoryListItem), findsNothing);
      expect(find.text('No games match this filter'), findsOneWidget);
      // The filter stays, so the user can switch back.
      expect(find.byType(MatchFormatFilterDropdown), findsOneWidget);
    });

    testWidgets('choosing EDH sends the filter to the bloc', (tester) async {
      await pumpPanel(tester, loaded(MatchFormatFilter.all));

      await tester.tap(find.byType(MatchFormatFilterDropdown));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EDH').last);
      await tester.pumpAndSettle();

      verify(
        () => matchHistoryBloc.add(
          const MatchFormatFilterChanged(MatchFormatFilter.commander),
        ),
      ).called(1);
    });
  });
}
