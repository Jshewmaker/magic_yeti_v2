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
    this.partner,
    this.firebaseId,
  });

  final Commander? commander;
  final String? playerName;
  final String playerId;
  final Commander? partner;
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
  const PlayerCommanderDamageIncremented({
    required this.commanderId,
    required this.damageType,
  });

  final String commanderId;
  final DamageType damageType;
  @override
  List<Object> get props => [commanderId, damageType];
}

class PlayerCommanderDamageDecremented extends PlayerEvent {
  const PlayerCommanderDamageDecremented({
    required this.commanderId,
    required this.damageType,
  });

  final String commanderId;
  final DamageType damageType;

  @override
  List<Object> get props => [commanderId, damageType];
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
