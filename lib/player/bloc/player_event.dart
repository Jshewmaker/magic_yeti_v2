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
    this.pictureUrl,
  });

  final String? pictureUrl;
  final String? playerName;
  final int playerId;
}

class UpdatePlayerLifeEvent extends PlayerEvent {
  const UpdatePlayerLifeEvent({
    required this.decrement,
    required this.playerId,
  });

  final bool decrement;
  final int playerId;
}

class UpdatePlayerLifeByXEvent extends PlayerEvent {
  const UpdatePlayerLifeByXEvent({
    required this.decrement,
    required this.playerId,
  });

  final bool decrement;
  final int playerId;
}

class PlayerStopDecrement extends PlayerEvent {
  const PlayerStopDecrement();
}

class PlayerDiesEvent extends PlayerEvent {
  const PlayerDiesEvent({required this.playerNumber});

  final int playerNumber;
}
