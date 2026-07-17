import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

class _MockScryfallRepository extends Mock implements ScryfallRepository {}

/// Mirrors the minimal single-player [GameModel] fixture used in
/// `test/home/match_history_bloc/match_history_bloc_test.dart`: a populated
/// `players` list is required by the bloc's stat calculators, but no
/// commander data is needed since these tests only assert on `range` and
/// `games.length`.
GameModel _game({required String id, required DateTime endTime}) {
  const player = Player(
    id: 'p1',
    name: 'Player 1',
    playerNumber: 1,
    lifePoints: 40,
    color: 0xFF000000,
    opponents: [],
    placement: 1,
    firebaseId: 'alice',
  );
  return GameModel(
    id: id,
    players: const [player],
    startTime: endTime.subtract(const Duration(hours: 1)),
    endTime: endTime,
    winnerId: 'p1',
    durationInSeconds: 3600,
  );
}

void main() {
  late ScryfallRepository scryfallRepository;

  final oldGame = _game(id: 'old', endTime: DateTime(2020));
  final newGame = _game(
    id: 'new',
    endTime: DateTime.now().subtract(const Duration(days: 1)),
  );

  setUp(() {
    scryfallRepository = _MockScryfallRepository();
  });

  StatsOverviewBloc buildBloc() =>
      StatsOverviewBloc(scryfallRepository: scryfallRepository);

  group('StatsOverviewBloc', () {
    group('CompileStatsOverviewData', () {
      blocTest<StatsOverviewBloc, StatsOverviewState>(
        'defaults to allTime and keeps every game',
        build: buildBloc,
        act: (bloc) => bloc.add(
          CompileStatsOverviewData(
            userId: 'alice',
            games: [oldGame, newGame],
          ),
        ),
        expect: () => [
          isA<StatsOverviewLoaded>()
              .having((s) => s.range, 'range', StatsTimeRange.allTime)
              .having((s) => s.games.length, 'games.length', 2),
        ],
      );
    });

    group('StatsTimeRangeChanged', () {
      blocTest<StatsOverviewBloc, StatsOverviewState>(
        'StatsTimeRangeChanged re-filters the games already held, without '
        'the caller re-supplying them',
        build: buildBloc,
        act: (bloc) async {
          bloc.add(
            CompileStatsOverviewData(
              userId: 'alice',
              games: [oldGame, newGame],
            ),
          );
          await Future<void>.delayed(Duration.zero);
          bloc.add(const StatsTimeRangeChanged(StatsTimeRange.last30Days));
        },
        skip: 1,
        expect: () => [
          isA<StatsOverviewLoaded>()
              .having((s) => s.range, 'range', StatsTimeRange.last30Days)
              .having((s) => s.games.length, 'games.length', 1),
        ],
      );
    });
  });
}
