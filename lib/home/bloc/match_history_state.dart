part of 'match_history_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class MatchHistoryState extends Equatable {
  const MatchHistoryState({
    this.status = HomeStatus.initial,
    this.games = const [],
    this.error,
  });

  final HomeStatus status;
  final List<GameModel> games;
  final String? error;

  MatchHistoryState copyWith({
    HomeStatus? status,
    List<GameModel>? games,
    String? error,
  }) {
    return MatchHistoryState(
      status: status ?? this.status,
      games: games ?? this.games,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, games, error];
}
