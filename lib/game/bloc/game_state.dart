part of 'game_bloc.dart';

enum GameStatus { initial, loading, running, finished, paused, error, reset }

class GameState extends Equatable {
  const GameState({
    this.status = GameStatus.initial,
    this.playerList = const [],
    this.winner,
    this.error,
    this.elapsedSeconds = 0,
  });

  final GameStatus status;
  final List<Player> playerList;
  final Player? winner;
  final String? error;
  final int elapsedSeconds;

  GameState copyWith({
    GameStatus? status,
    List<Player>? playerList,
    Player? winner,
    String? error,
    int? elapsedSeconds,
  }) {
    return GameState(
      status: status ?? this.status,
      playerList: playerList ?? this.playerList,
      winner: winner ?? this.winner,
      error: error ?? this.error,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  @override
  List<Object?> get props =>
      [status, playerList, winner, error, elapsedSeconds];
}
