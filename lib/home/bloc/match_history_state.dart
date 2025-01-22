part of 'match_history_bloc.dart';

enum HomeStatus {
  initial,
  loadingHistory,
  loadingHistorySuccess,
  loadingStats,
  loadingStatsSuccess,
  failure
}

class MatchHistoryState extends Equatable {
  const MatchHistoryState({
    this.status = HomeStatus.initial,
    this.games = const [],
    this.error,
    this.uniqueCommanderCount = 0,
    this.totalWins = 0,
    this.winPercentage = 0,
    this.shortestGameDuration = '0',
    this.longestGameDuration = '0',
    this.averagePlacement = 0,
    this.timesWentFirst = 0,
  });

  final HomeStatus status;
  final List<GameModel> games;
  final String? error;
  final int uniqueCommanderCount;
  final int totalWins;
  final int winPercentage;
  final String shortestGameDuration;
  final String longestGameDuration;
  final double averagePlacement;
  final int timesWentFirst;

  MatchHistoryState copyWith({
    HomeStatus? status,
    List<GameModel>? games,
    String? error,
    int? uniqueCommanderCount,
    int? totalWins,
    int? winPercentage,
    String? shortestGameDuration,
    String? longestGameDuration,
    double? averagePlacement,
    int? timesWentFirst,
  }) {
    return MatchHistoryState(
      status: status ?? this.status,
      games: games ?? this.games,
      error: error ?? this.error,
      uniqueCommanderCount: uniqueCommanderCount ?? this.uniqueCommanderCount,
      totalWins: totalWins ?? this.totalWins,
      winPercentage: winPercentage ?? this.winPercentage,
      shortestGameDuration: shortestGameDuration ?? this.shortestGameDuration,
      longestGameDuration: longestGameDuration ?? this.longestGameDuration,
      averagePlacement: averagePlacement ?? this.averagePlacement,
      timesWentFirst: timesWentFirst ?? this.timesWentFirst,
    );
  }

  @override
  List<Object?> get props => [
        status,
        games,
        error,
        uniqueCommanderCount,
        totalWins,
        winPercentage,
        shortestGameDuration,
        longestGameDuration,
        averagePlacement,
        timesWentFirst,
      ];
}
