import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_stats.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:player_repository/player_repository.dart';

Player _seat(String id, String firebaseId, int tod) => Player(
  id: id,
  name: 'Name-$id',
  playerNumber: 0,
  lifePoints: 40,
  color: 0xFF000000,
  opponents: const [],
  placement: 1,
  timeOfDeath: tod,
  firebaseId: firebaseId,
);

/// A shared pod (me + friend) ending at [end]. `me` wins.
GameModel _sharedGameAt(DateTime end) {
  final start = end.subtract(const Duration(hours: 2));
  return GameModel(
    id: 'g-${end.millisecondsSinceEpoch}',
    winnerId: 'me-seat',
    startTime: start,
    endTime: end,
    durationInSeconds: 7200,
    players: [
      _seat('me-seat', 'me', end.millisecondsSinceEpoch),
      _seat('friend-seat', 'friend', start.millisecondsSinceEpoch + 1000),
    ],
  );
}

void main() {
  group('FriendStatsBloc', () {
    blocTest<FriendStatsBloc, FriendStatsState>(
      'emits loading then loaded with computed stats, range all-time',
      build: FriendStatsBloc.new,
      act: (bloc) => bloc.add(
        CompileFriendStats(
          myId: 'me',
          friendId: 'friend',
          games: [_sharedGameAt(DateTime(2026, 1, 1, 14))],
        ),
      ),
      expect: () => [
        isA<FriendStatsLoading>(),
        isA<FriendStatsLoaded>()
            .having((s) => s.stats.sharedPods, 'sharedPods', 1)
            .having((s) => s.range, 'range', StatsTimeRange.allTime),
      ],
    );

    blocTest<FriendStatsBloc, FriendStatsState>(
      'loaded stats reflect an empty shared history',
      build: FriendStatsBloc.new,
      act: (bloc) => bloc.add(
        const CompileFriendStats(myId: 'me', friendId: 'friend', games: []),
      ),
      expect: () => [
        isA<FriendStatsLoading>(),
        isA<FriendStatsLoaded>().having(
          (s) => s.stats.sharedPods,
          'sharedPods',
          0,
        ),
      ],
    );

    blocTest<FriendStatsBloc, FriendStatsState>(
      'range change filters games by endTime and recomputes',
      build: FriendStatsBloc.new,
      act: (bloc) {
        final now = DateTime.now();
        bloc
          ..add(
            CompileFriendStats(
              myId: 'me',
              friendId: 'friend',
              games: [
                _sharedGameAt(now.subtract(const Duration(days: 5))),
                _sharedGameAt(now.subtract(const Duration(days: 400))),
              ],
            ),
          )
          ..add(const FriendStatsRangeChanged(StatsTimeRange.last30Days));
      },
      // Skip the loading+loaded pair emitted by the initial compile.
      skip: 2,
      expect: () => [
        isA<FriendStatsLoading>(),
        isA<FriendStatsLoaded>()
            .having((s) => s.stats.sharedPods, 'sharedPods', 1)
            .having((s) => s.range, 'range', StatsTimeRange.last30Days),
      ],
    );
  });
}
