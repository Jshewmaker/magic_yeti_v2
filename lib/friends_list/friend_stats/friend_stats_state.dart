part of 'friend_stats_bloc.dart';

sealed class FriendStatsState extends Equatable {
  const FriendStatsState();

  @override
  List<Object?> get props => [];
}

final class FriendStatsInitial extends FriendStatsState {}

final class FriendStatsLoading extends FriendStatsState {}

final class FriendStatsLoaded extends FriendStatsState {
  const FriendStatsLoaded(this.stats, {this.range = StatsTimeRange.allTime});

  final FriendHeadToHead stats;
  final StatsTimeRange range;

  @override
  List<Object?> get props => [stats, range];
}

final class FriendStatsFailure extends FriendStatsState {
  const FriendStatsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
