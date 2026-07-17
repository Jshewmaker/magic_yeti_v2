part of 'stats_overview_bloc.dart';

sealed class StatsOverviewEvent extends Equatable {
  const StatsOverviewEvent();

  @override
  List<Object> get props => [];
}

final class LoadStatsOverview extends StatsOverviewEvent {
  const LoadStatsOverview();
}

final class CompileStatsOverviewData extends StatsOverviewEvent {
  const CompileStatsOverviewData({
    required this.userId,
    required this.games,
  });

  final String userId;
  final List<GameModel> games;

  @override
  List<Object> get props => [userId, games];
}

/// Re-filters the games already held by the bloc to a new time range.
///
/// The bloc keeps the last compiled game list, so changing the range does
/// not require the caller to re-supply it.
final class StatsTimeRangeChanged extends StatsOverviewEvent {
  const StatsTimeRangeChanged(this.range);
  final StatsTimeRange range;

  @override
  List<Object> get props => [range];
}
