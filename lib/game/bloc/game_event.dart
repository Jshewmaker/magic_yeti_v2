part of 'game_bloc.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request restoring the previous game state (undo game over)
class GameRestoreRequested extends GameEvent {
  const GameRestoreRequested();

  @override
  List<Object?> get props => [];
}

final class CreateGameEvent extends GameEvent {
  const CreateGameEvent({
    required this.numberOfPlayers,
    required this.startingLifePoints,
  });
  final int numberOfPlayers;
  final int startingLifePoints;
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

class GameUpdateTimerEvent extends GameEvent {
  const GameUpdateTimerEvent({
    required this.gameLength,
  });
  final int gameLength;

  @override
  List<Object?> get props => [gameLength];
}

class PlayerRepositoryUpdateEvent extends GameEvent {
  const PlayerRepositoryUpdateEvent({
    required this.players,
  });
  final List<Player> players;

  @override
  List<Object> get props => [players];
}

class GamePauseEvent extends GameEvent {
  const GamePauseEvent();
}

class GameResumeEvent extends GameEvent {
  const GameResumeEvent();
}

enum PlayerAction {
  increment,
  decrement,
  updateName,
  updatePfP,
  died,
}
