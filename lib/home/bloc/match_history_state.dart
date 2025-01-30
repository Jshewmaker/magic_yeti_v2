part of 'match_history_bloc.dart';

enum MatchHistoryStatus {
  initial,
  loadingHistory,
  loadingHistorySuccess,
  loadingStats,
  loadingStatsSuccess,
  failure
}

class MatchHistoryState extends Equatable {
  const MatchHistoryState({
    this.status = MatchHistoryStatus.initial,
    this.userId = '',
    this.games = const [],
    this.error,
    this.uniqueCommanderCount = 0,
    this.totalWins = 0,
    this.winPercentage = 0,
    this.shortestGameDuration = '0',
    this.longestGameDuration = '0',
    this.averagePlacement = 0,
    this.timesWentFirst = 0,
    this.avgEdhRecRank = 0,
  });

  final MatchHistoryStatus status;
  final String userId;
  final List<GameModel> games;
  final String? error;
  final int uniqueCommanderCount;
  final int totalWins;
  final int winPercentage;
  final String shortestGameDuration;
  final String longestGameDuration;
  final double averagePlacement;
  final int timesWentFirst;
  final double avgEdhRecRank;

  MatchHistoryState copyWith({
    MatchHistoryStatus? status,
    String? userId,
    List<GameModel>? games,
    String? error,
    int? uniqueCommanderCount,
    int? totalWins,
    int? winPercentage,
    String? shortestGameDuration,
    String? longestGameDuration,
    double? averagePlacement,
    int? timesWentFirst,
    double? avgEdhRecRank,
  }) {
    return MatchHistoryState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      games: games ?? this.games,
      error: error ?? this.error,
      uniqueCommanderCount: uniqueCommanderCount ?? this.uniqueCommanderCount,
      totalWins: totalWins ?? this.totalWins,
      winPercentage: winPercentage ?? this.winPercentage,
      shortestGameDuration: shortestGameDuration ?? this.shortestGameDuration,
      longestGameDuration: longestGameDuration ?? this.longestGameDuration,
      averagePlacement: averagePlacement ?? this.averagePlacement,
      timesWentFirst: timesWentFirst ?? this.timesWentFirst,
      avgEdhRecRank: avgEdhRecRank ?? this.avgEdhRecRank,
    );
  }

  @override
  List<Object?> get props => [
        status,
        games,
        userId,
        error,
        uniqueCommanderCount,
        totalWins,
        winPercentage,
        shortestGameDuration,
        longestGameDuration,
        averagePlacement,
        timesWentFirst,
        avgEdhRecRank,
      ];
}
