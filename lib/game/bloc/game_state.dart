part of 'game_bloc.dart';

enum GameStatus {
  initial,
  loading,
  idle,
  gameOver,
  failure,
}

final class GameState extends Equatable {
  const GameState({
    this.status = GameStatus.initial,
    this.playerList = const [],
  });

  final GameStatus status;
  final List<Player> playerList;

  GameState copyWith({
    GameStatus? status,
    List<Player>? playerList,
  }) {
    return GameState(
      status: status ?? this.status,
      playerList: playerList ?? this.playerList,
    );
  }

  @override
  List<Object> get props => [
        status,
        playerList,
      ];
}
