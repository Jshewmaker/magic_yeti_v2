part of 'game_bloc.dart';

sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

final class CreateGameEvent extends GameEvent {
  const CreateGameEvent({required this.numberOfPlayers});
  final int numberOfPlayers;
}

final class UpdatePlayerEvent extends GameEvent {
  const UpdatePlayerEvent({
    required this.player,
    required this.action,
  });

  final Player player;
  final PlayerAction action;
}

final class GameOverEvent extends GameEvent {
  const GameOverEvent();
}

final class GamePlayerUpdatedEvent extends GameEvent {
  const GamePlayerUpdatedEvent({required this.player});

  final Player player;
}

final class GameResetEvent extends GameEvent {
  const GameResetEvent();
}

enum PlayerAction {
  increment,
  decrement,
  updateName,
  updatePfP,
}
