part of 'game_bloc.dart';

enum GameStatus { initial, loading, running, finished, paused, error, reset }

class GameState extends Equatable {
  const GameState({
    this.status = GameStatus.initial,
    this.playerList = const [],
    this.winner,
    this.elapsedSeconds = 0,
    this.startTime,
    this.firstPlayerId,
    this.gameModel,
    this.error,
  });

  final GameStatus status;
  final GameModel? gameModel;
  final List<Player> playerList;
  final Player? winner;
  final int elapsedSeconds;
  final DateTime? startTime;
  final String? firstPlayerId;
  final String? error;

  GameState copyWith({
    GameStatus? status,
    int? gameId,
    List<Player>? playerList,
    Player? winner,
    String? error,
    int? elapsedSeconds,
    DateTime? startTime,
    String? hostId,
    String? firstPlayerId,
    GameModel? gameModel,
  }) {
    return GameState(
      status: status ?? this.status,
      playerList: playerList ?? this.playerList,
      winner: winner ?? this.winner,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startTime: startTime ?? this.startTime,
      error: error ?? this.error,
      firstPlayerId: firstPlayerId ?? this.firstPlayerId,
      gameModel: gameModel ?? this.gameModel,
    );
  }

  @override
  List<Object?> get props => [
        status,
        playerList,
        winner,
        elapsedSeconds,
        startTime,
        firstPlayerId,
        error,
        gameModel,
      ];
}
