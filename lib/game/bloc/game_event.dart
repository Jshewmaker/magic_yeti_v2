part of 'game_bloc.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

final class CreateGameEvent extends GameEvent {
  const CreateGameEvent({required this.numberOfPlayers});
  final int numberOfPlayers;
}

class GameStartEvent extends GameEvent {
  const GameStartEvent();
}

class GameResetEvent extends GameEvent {
  const GameResetEvent();
}

class GameFinishEvent extends GameEvent {
  const GameFinishEvent({required this.winner});

  final Player winner;

  @override
  List<Object?> get props => [winner];
}

enum PlayerAction {
  increment,
  decrement,
  updateName,
  updatePfP,
  died,
}
