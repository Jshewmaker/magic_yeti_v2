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
