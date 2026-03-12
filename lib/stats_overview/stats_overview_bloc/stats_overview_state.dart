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
    required this.averageGameDuration,
    required this.winRateWhenFirst,
    required this.bestCommander,
    required this.currentStreak,
    required this.mostCommonOpponent,
    required this.nemesis,
    required this.avgCommanderDamageTaken,
    required this.timesKilledByCommander,
    required this.bestColorCombo,
    required this.bestSingleColor,
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
  final String averageGameDuration;
  final String winRateWhenFirst;
  final String bestCommander;
  final String currentStreak;
  final String mostCommonOpponent;
  final String nemesis;
  final String avgCommanderDamageTaken;
  final int timesKilledByCommander;
  final String bestColorCombo;
  final String bestSingleColor;

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
        averageGameDuration,
        winRateWhenFirst,
        bestCommander,
        currentStreak,
        mostCommonOpponent,
        nemesis,
        avgCommanderDamageTaken,
        timesKilledByCommander,
        bestColorCombo,
        bestSingleColor,
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
