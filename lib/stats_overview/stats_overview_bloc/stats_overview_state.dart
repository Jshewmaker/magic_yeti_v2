part of 'stats_overview_bloc.dart';

sealed class StatsOverviewState extends Equatable {
  const StatsOverviewState();

  @override
  List<Object> get props => [];
}

final class StatsOverviewInitial extends StatsOverviewState {}

final class StatsOverviewLoading extends StatsOverviewState {}

final class StatsOverviewLoaded extends StatsOverviewState {
  const StatsOverviewLoaded({
    required this.userId,
    required this.games,
    required this.uniqueCommanderCount,
    required this.totalWins,
    required this.winPercentage,
    required this.shortestGameDuration,
    required this.longestGameDuration,
    required this.averagePlacement,
    required this.timesWentFirst,
    required this.mostPlayedCommander,
  });

  final String userId;
  final List<GameModel> games;
  final int uniqueCommanderCount;
  final int totalWins;
  final int winPercentage;
  final String shortestGameDuration;
  final String longestGameDuration;
  final double averagePlacement;
  final int timesWentFirst;
  final String mostPlayedCommander;

  @override
  List<Object> get props => [
        userId,
        games,
        uniqueCommanderCount,
        totalWins,
        winPercentage,
        shortestGameDuration,
        longestGameDuration,
        averagePlacement,
        timesWentFirst,
        mostPlayedCommander,
      ];
}

final class StatsOverviewFailure extends StatsOverviewState {
  const StatsOverviewFailure({
    required this.error,
  });

  final String error;

  @override
  List<Object> get props => [error];
}
