import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

GameModel _game({required String id, required DateTime endTime}) {
  final player = Player(
    id: 'p1',
    name: 'Player 1',
    playerNumber: 1,
    lifePoints: 40,
    color: 0xFF000000,
    opponents: const [],
    placement: 1,
  );
  return GameModel(
    id: id,
    players: [player],
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
          when(() => databaseRepository.getGames('user-1'))
              .thenAnswer((_) => firstUserGames.stream);
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
          when(() => databaseRepository.getGame('ROOM'))
              .thenAnswer((_) async => newerGame);
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
  });
}
