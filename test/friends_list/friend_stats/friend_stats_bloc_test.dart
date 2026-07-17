import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_stats.dart';
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

GameModel _sharedGame() {
  final start = DateTime(2026, 1, 1, 12);
  final end = DateTime(2026, 1, 1, 14);
  return GameModel(
    id: 'g1',
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
      'emits loading then loaded with computed stats',
      build: FriendStatsBloc.new,
      act: (bloc) => bloc.add(
        CompileFriendStats(
          myId: 'me',
          friendId: 'friend',
          games: [_sharedGame()],
        ),
      ),
      expect: () => [
        isA<FriendStatsLoading>(),
        isA<FriendStatsLoaded>().having(
          (s) => s.stats.sharedPods,
          'sharedPods',
          1,
        ),
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
  });
}
