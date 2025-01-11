part of 'game_bloc.dart';

enum GameStatus { initial, loading, running, finished, paused, error, reset }

class GameState extends Equatable {
  const GameState({
    this.status = GameStatus.initial,
    this.playerList = const [],
    this.winner,
    this.elapsedSeconds = 0,
    this.startTime,
  });

  final GameStatus status;
  final List<Player> playerList;
  final Player? winner;
  final int elapsedSeconds;
  final DateTime? startTime;

  GameState copyWith({
    GameStatus? status,
    int? gameId,
    List<Player>? playerList,
    Player? winner,
    String? error,
    int? elapsedSeconds,
    DateTime? startTime,
  }) {
    return GameState(
      status: status ?? this.status,
      playerList: playerList ?? this.playerList,
      winner: winner ?? this.winner,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  List<Object?> get props => [
        status,
        playerList,
        winner,
        elapsedSeconds,
        startTime,
      ];
}
