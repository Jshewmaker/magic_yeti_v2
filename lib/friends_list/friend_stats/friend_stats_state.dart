part of 'friend_stats_bloc.dart';

sealed class FriendStatsState extends Equatable {
  const FriendStatsState();

  @override
  List<Object?> get props => [];
}

final class FriendStatsInitial extends FriendStatsState {}

final class FriendStatsLoading extends FriendStatsState {}

final class FriendStatsLoaded extends FriendStatsState {
  const FriendStatsLoaded(this.stats);

  final FriendHeadToHead stats;

  @override
  List<Object?> get props => [stats];
}

final class FriendStatsFailure extends FriendStatsState {
  const FriendStatsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
