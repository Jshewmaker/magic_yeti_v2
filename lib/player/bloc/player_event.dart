part of 'player_bloc.dart';

sealed class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object> get props => [];
}

class UpdatePlayerInfoEvent extends PlayerEvent {
  const UpdatePlayerInfoEvent({
    required this.player,
  });

  final Player player;
}

class UpdatePlayerLifeEvent extends PlayerEvent {
  const UpdatePlayerLifeEvent({
    required this.player,
    required this.decrement,
  });
  final Player player;

  final bool decrement;
}

class UpdatePlayerLifeByXEvent extends PlayerEvent {
  const UpdatePlayerLifeByXEvent({
    required this.player,
    required this.decrement,
  });
  final Player player;
  final bool decrement;
}

class PlayerStopDecrement extends PlayerEvent {}

class PlayerDiesEvent extends PlayerEvent {
  const PlayerDiesEvent({required this.playerNumber});

  final int playerNumber;
}
