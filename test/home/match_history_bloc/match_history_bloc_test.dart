import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

GameModel _game({
  required String id,
  required DateTime endTime,
  int playerCount = 1,
}) {
  final players = [
    for (var i = 1; i <= playerCount; i++)
      Player(
        id: 'p$i',
        name: 'Player $i',
        playerNumber: i,
        lifePoints: 40,
        color: 0xFF000000,
        opponents: const [],
        placement: i,
      ),
  ];
  return GameModel(
    id: id,
    players: players,
    startTime: endTime.subtract(const Duration(hours: 1)),
    endTime: endTime,
    winnerId: 'p1',
    durationInSeconds: 3600,
  );
}

void main() {
  late FirebaseDatabaseRepository databaseRepository;

  final olderGame = _game(id: 'older', endTime: DateTime(2026, 1, 1));
  final newerGame = _game(id: 'newer', endTime: DateTime(2026, 6, 1));

  setUp(() {
    databaseRepository = _MockFirebaseDatabaseRepository();
  });

  MatchHistoryBloc buildBloc() =>
      MatchHistoryBloc(databaseRepository: databaseRepository);

  group('MatchHistoryBloc', () {
    group('LoadMatchHistory', () {
      blocTest<MatchHistoryBloc, MatchHistoryState>(
        'emits loading then success with games sorted newest first',
        setUp: () {
          when(() => databaseRepository.getGames('user-1')).thenAnswer(
            (_) => Stream.value([olderGame, newerGame]),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadMatchHistory(userId: 'user-1')),
        expect: () => [
          const MatchHistoryState(
            status: MatchHistoryStatus.loadingHistory,
            userId: 'user-1',
          ),
          MatchHistoryState(
            status: MatchHistoryStatus.loadingHistorySuccess,
            userId: 'user-1',
            games: [newerGame, olderGame],
          ),
        ],
      );

      blocTest<MatchHistoryBloc, MatchHistoryState>(
        'clears games and unsubscribes when userId is empty',
        seed: () => MatchHistoryState(
          status: MatchHistoryStatus.loadingHistorySuccess,
          userId: 'user-1',
          games: [newerGame],
        ),
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadMatchHistory(userId: '')),
        expect: () => [
          const MatchHistoryState(
            status: MatchHistoryStatus.loadingHistorySuccess,
            games: [],
          ),
        ],
      );

      blocTest<MatchHistoryBloc, MatchHistoryState>(
        'a new LoadMatchHistory cancels the previous subscription',
        setUp: () {
          final firstUserGames = StreamController<List<GameModel>>();
          when(
            () => databaseRepository.getGames('user-1'),
          ).thenAnswer((_) => firstUserGames.stream);
          when(() => databaseRepository.getGames('user-2')).thenAnswer(
            (_) => Stream.value([newerGame]),
          );
          addTearDown(firstUserGames.close);
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const LoadMatchHistory(userId: 'user-1'));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const LoadMatchHistory(userId: 'user-2'));
        },
        expect: () => [
          const MatchHistoryState(
            status: MatchHistoryStatus.loadingHistory,
            userId: 'user-1',
          ),
          const MatchHistoryState(
            status: MatchHistoryStatus.loadingHistory,
            userId: 'user-2',
          ),
          MatchHistoryState(
            status: MatchHistoryStatus.loadingHistorySuccess,
            userId: 'user-2',
            games: [newerGame],
          ),
        ],
      );

      blocTest<MatchHistoryBloc, MatchHistoryState>(
        'emits failure when the games stream errors',
        setUp: () {
          when(() => databaseRepository.getGames('user-1')).thenAnswer(
            (_) => Stream.error(Exception('boom')),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadMatchHistory(userId: 'user-1')),
        expect: () => [
          const MatchHistoryState(
            status: MatchHistoryStatus.loadingHistory,
            userId: 'user-1',
          ),
          const MatchHistoryState(
            status: MatchHistoryStatus.failure,
            userId: 'user-1',
            error: 'Exception: boom',
          ),
        ],
      );
    });

    group('AddMatchToPlayerHistoryEvent', () {
      blocTest<MatchHistoryBloc, MatchHistoryState>(
        'emits gameNotFound when the room id does not exist',
        setUp: () {
          when(() => databaseRepository.getGame('ROOM')).thenThrow(
            GameNotFoundException(
              message: 'not found',
              stackTrace: StackTrace.current,
            ),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(
          const AddMatchToPlayerHistoryEvent(roomId: 'ROOM', playerId: 'p1'),
        ),
        expect: () => [
          const MatchHistoryState(
            status: MatchHistoryStatus.loadingHistorySuccess,
          ),
          isA<MatchHistoryState>().having(
            (s) => s.status,
            'status',
            MatchHistoryStatus.gameNotFound,
          ),
        ],
      );

      blocTest<MatchHistoryBloc, MatchHistoryState>(
        'adds the match and lets the games stream deliver the update',
        setUp: () {
          when(
            () => databaseRepository.getGame('ROOM'),
          ).thenAnswer((_) async => newerGame);
          when(
            () => databaseRepository.addMatchToPlayerHistory(newerGame, 'p1'),
          ).thenAnswer((_) async {});
        },
        build: buildBloc,
        act: (bloc) => bloc.add(
          const AddMatchToPlayerHistoryEvent(roomId: 'ROOM', playerId: 'p1'),
        ),
        expect: () => [
          const MatchHistoryState(
            status: MatchHistoryStatus.loadingHistorySuccess,
          ),
        ],
        verify: (_) {
          verify(
            () => databaseRepository.addMatchToPlayerHistory(newerGame, 'p1'),
          ).called(1);
        },
      );
    });

    group('format filter', () {
      final commanderGame = _game(
        id: 'edh',
        endTime: DateTime(2026, 3, 1),
        playerCount: 4,
      );
      final constructedGame = _game(
        id: '1v1',
        endTime: DateTime(2026, 2, 1),
        playerCount: 2,
      );
      final loaded = MatchHistoryState(
        status: MatchHistoryStatus.loadingHistorySuccess,
        userId: 'user-1',
        games: [commanderGame, constructedGame],
      );

      test('shows every game by default', () {
        expect(loaded.formatFilter, MatchFormatFilter.all);
        expect(loaded.filteredGames, [commanderGame, constructedGame]);
      });

      test('EDH keeps games with more than two players', () {
        expect(
          loaded
              .copyWith(formatFilter: MatchFormatFilter.commander)
              .filteredGames,
          [commanderGame],
        );
      });

      test('constructed keeps two-player games', () {
        expect(
          loaded
              .copyWith(formatFilter: MatchFormatFilter.constructed)
              .filteredGames,
          [constructedGame],
        );
      });

      blocTest<MatchHistoryBloc, MatchHistoryState>(
        'MatchFormatFilterChanged sets the filter and keeps all games',
        build: buildBloc,
        seed: () => loaded,
        act: (bloc) => bloc.add(
          const MatchFormatFilterChanged(MatchFormatFilter.constructed),
        ),
        expect: () => [
          loaded.copyWith(formatFilter: MatchFormatFilter.constructed),
        ],
        verify: (bloc) =>
            expect(bloc.state.games, [commanderGame, constructedGame]),
      );

      blocTest<MatchHistoryBloc, MatchHistoryState>(
        'keeps the filter when new games arrive',
        setUp: () {
          when(() => databaseRepository.getGames('user-1')).thenAnswer(
            (_) => Stream.value([commanderGame, constructedGame]),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc
          ..add(const MatchFormatFilterChanged(MatchFormatFilter.commander))
          ..add(const LoadMatchHistory(userId: 'user-1')),
        verify: (bloc) {
          expect(bloc.state.formatFilter, MatchFormatFilter.commander);
          expect(bloc.state.filteredGames, [commanderGame]);
        },
      );
    });
  });
}
