part of 'match_history_bloc.dart';

enum MatchHistoryStatus {
  initial,
  loadingHistory,
  loadingHistorySuccess,
  gameNotFound,
  failure
}

class MatchHistoryState extends Equatable {
  const MatchHistoryState({
    this.status = MatchHistoryStatus.initial,
    this.userId = '',
    this.games = const [],
    this.error,
  });

  final MatchHistoryStatus status;
  final String userId;
  final List<GameModel> games;
  final String? error;

  MatchHistoryState copyWith({
    MatchHistoryStatus? status,
    String? userId,
    List<GameModel>? games,
    String? error,
  }) {
    return MatchHistoryState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      games: games ?? this.games,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        games,
        userId,
        error,
      ];
}
