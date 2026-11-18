import 'package:app_ui/app_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/home/widgets/match_format_filter.dart';
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

GameModel _game(String id, int playerCount) => GameModel(
  id: id,
  winnerId: 'me',
  startTime: DateTime(2026, 10),
  endTime: DateTime(2026, 10, 1, 1),
  durationInSeconds: 3600,
  players: [
    for (var i = 0; i < playerCount; i++)
      Player(
        id: i == 0 ? 'me' : 'p$i',
        firebaseId: i == 0 ? 'me' : null,
        name: 'Player $i',
        playerNumber: i,
        lifePoints: 0,
        color: 0xFF000000,
        opponents: const [],
        placement: i + 1,
      ),
  ],
);

void main() {
  late _MockAppBloc appBloc;
  late _MockMatchHistoryBloc matchHistoryBloc;

  final games = [_game('edh-1', 4), _game('edh-2', 4), _game('1v1', 2)];

  setUp(() {
    appBloc = _MockAppBloc();
    matchHistoryBloc = _MockMatchHistoryBloc();
    when(
      () => appBloc.state,
    ).thenReturn(const AppState.authenticated(User(id: 'me')));
  });

  Future<void> pumpStats(WidgetTester tester, MatchFormatFilter filter) async {
    // Tall enough that the grid builds every tile.
    tester.view.physicalSize = const Size(400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    when(() => matchHistoryBloc.state).thenReturn(
      MatchHistoryState(
        status: MatchHistoryStatus.loadingHistorySuccess,
        games: games,
        formatFilter: filter,
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

  String totalGames(WidgetTester tester) => tester
      .widgetList<StatsWidget>(find.byType(StatsWidget))
      .firstWhere((w) => w.title == 'Total Games')
      .stat;

  bool showsCommanderDamage(WidgetTester tester) => tester
      .widgetList<StatsWidget>(find.byType(StatsWidget))
      .any((w) => w.title.contains('Commander\nDamage'));

  group('StatsOverviewWidget format filter', () {
    testWidgets('counts every game for All games', (tester) async {
      await pumpStats(tester, MatchFormatFilter.all);

      expect(find.byType(MatchFormatFilterDropdown), findsOneWidget);
      expect(totalGames(tester), '3');
      expect(showsCommanderDamage(tester), isTrue);
    });

    testWidgets('counts only EDH games for EDH', (tester) async {
      await pumpStats(tester, MatchFormatFilter.commander);

      expect(totalGames(tester), '2');
      expect(showsCommanderDamage(tester), isTrue);
    });

    testWidgets('counts only constructed games, with no commander damage '
        'tiles, for Constructed', (tester) async {
      await pumpStats(tester, MatchFormatFilter.constructed);

      expect(totalGames(tester), '1');
      expect(showsCommanderDamage(tester), isFalse);
    });
  });
}
