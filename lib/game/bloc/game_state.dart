part of 'game_bloc.dart';

enum GameStatus { initial, loading, running, finished, error }

class GameState extends Equatable {
  const GameState({
    this.status = GameStatus.initial,
    this.playerList = const [],
    this.winner,
    this.error,
  });

  final GameStatus status;
  final List<Player> playerList;
  final Player? winner;
  final String? error;

  GameState copyWith({
    GameStatus? status,
    List<Player>? playerList,
    Player? winner,
    String? error,
  }) {
    return GameState(
      status: status ?? this.status,
      playerList: playerList ?? this.playerList,
      winner: winner ?? this.winner,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, playerList, winner, error];
}
