part of 'game_bloc.dart';

sealed class GameState extends Equatable {
  const GameState();

  @override
  List<Object> get props => [];
}

final class GameInitial extends GameState {
  const GameInitial();
}

final class GameLoading extends GameState {
  const GameLoading();
}

final class GameRunning extends GameState {
  const GameRunning({
    required this.playerList,
  });

  final List<Player> playerList;

  @override
  List<Object> get props => [playerList];
}

final class GameFinished extends GameState {
  const GameFinished({
    required this.playerList,
    required this.winner,
  });

  final List<Player> playerList;
  final Player winner;

  @override
  List<Object> get props => [playerList, winner];
}

final class GameError extends GameState {
  const GameError({required this.error});

  final String error;

  @override
  List<Object> get props => [error];
}
