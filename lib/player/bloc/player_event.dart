part of 'player_bloc.dart';

sealed class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object> get props => [];
}

class PlayerEventReset extends PlayerEvent {}

class UpdatePlayerInfoEvent extends PlayerEvent {
  const UpdatePlayerInfoEvent({
    required this.playerId,
    this.playerName,
    this.commander,
    this.firebaseId,
  });

  final Commander? commander;
  final String? playerName;
  final String playerId;
  final String? firebaseId;
}

class UpdatePlayerLifeEvent extends PlayerEvent {
  const UpdatePlayerLifeEvent({
    required this.decrement,
    required this.playerId,
  });

  final bool decrement;
  final String playerId;
}

class PlayerCommanderDamageIncremented extends PlayerEvent {
  const PlayerCommanderDamageIncremented({required this.commanderId});

  final String commanderId;

  @override
  List<Object> get props => [commanderId];
}

class PlayerCommanderDamageDecremented extends PlayerEvent {
  const PlayerCommanderDamageDecremented({required this.commanderId});

  final String commanderId;

  @override
  List<Object> get props => [commanderId];
}

class UpdatePlayerLifeByXEvent extends PlayerEvent {
  const UpdatePlayerLifeByXEvent({
    required this.decrement,
    required this.playerId,
  });

  final bool decrement;
  final String playerId;
}

class PlayerStopDecrement extends PlayerEvent {
  const PlayerStopDecrement();
}

class PlayerDiesEvent extends PlayerEvent {
  const PlayerDiesEvent({required this.playerNumber});

  final int playerNumber;
}

/// Event when the repository updates a player
final class PlayerRepositoryUpdateEvent extends PlayerEvent {
  const PlayerRepositoryUpdateEvent({required this.player});

  final Player player;

  @override
  List<Object> get props => [player];
}
