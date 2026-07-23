part of 'friend_stats_bloc.dart';

sealed class FriendStatsEvent extends Equatable {
  const FriendStatsEvent();

  @override
  List<Object?> get props => [];
}

/// Recompute head-to-head stats for [friendId] from the user's [games].
final class CompileFriendStats extends FriendStatsEvent {
  const CompileFriendStats({
    required this.myId,
    required this.friendId,
    required this.games,
  });

  final String myId;
  final String friendId;
  final List<GameModel> games;

  @override
  List<Object?> get props => [myId, friendId, games];
}

/// Change the time window the head-to-head stats are computed over. Reuses the
/// retained games/ids from the last [CompileFriendStats].
final class FriendStatsRangeChanged extends FriendStatsEvent {
  const FriendStatsRangeChanged(this.range);

  final StatsTimeRange range;

  @override
  List<Object?> get props => [range];
}
