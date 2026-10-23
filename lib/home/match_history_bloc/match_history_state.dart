part of 'match_history_bloc.dart';

enum MatchHistoryStatus {
  initial,
  loadingHistory,
  loadingHistorySuccess,
  gameNotFound,
  failure,
}

/// Which games the home screen shows: all of them, only Commander (EDH)
/// games, or only 1v1 constructed games. See [GameModel.isCommanderGame].
enum MatchFormatFilter {
  all,
  commander,
  constructed;

  bool matches(GameModel game) => switch (this) {
    MatchFormatFilter.all => true,
    MatchFormatFilter.commander => game.isCommanderGame,
    MatchFormatFilter.constructed => !game.isCommanderGame,
  };
}

class MatchHistoryState extends Equatable {
  const MatchHistoryState({
    this.status = MatchHistoryStatus.initial,
    this.userId = '',
    this.games = const [],
    this.formatFilter = MatchFormatFilter.all,
    this.error,
  });

  final MatchHistoryStatus status;
  final String userId;

  /// Every game in the user's history, whatever [formatFilter] is set to.
  final List<GameModel> games;
  final MatchFormatFilter formatFilter;
  final String? error;

  /// The games that match [formatFilter], most recent first.
  List<GameModel> get filteredGames => formatFilter == MatchFormatFilter.all
      ? games
      : games.where(formatFilter.matches).toList();

  MatchHistoryState copyWith({
    MatchHistoryStatus? status,
    String? userId,
    List<GameModel>? games,
    MatchFormatFilter? formatFilter,
    String? error,
  }) {
    return MatchHistoryState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      games: games ?? this.games,
      formatFilter: formatFilter ?? this.formatFilter,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    games,
    userId,
    formatFilter,
    error,
  ];
}
