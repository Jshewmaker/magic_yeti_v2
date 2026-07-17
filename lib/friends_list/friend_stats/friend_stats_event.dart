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
