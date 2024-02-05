part of 'player_bloc.dart';

sealed class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object> get props => [];
}

class CreatePlayerEvent extends PlayerEvent {
  const CreatePlayerEvent({required this.numberOfPlayers});

  final int numberOfPlayers;
}

class UpdateCommanderEvent extends PlayerEvent {
  const UpdateCommanderEvent({
    required this.pictureUrl,
    required this.playerNumber,
  });

  final String pictureUrl;
  final int playerNumber;
}

class UpdatePlayerNameEvent extends PlayerEvent {
  const UpdatePlayerNameEvent({required this.playerNumber, required this.name});
  final int playerNumber;
  final String name;
}

class UpdatePlayerLifeEvent extends PlayerEvent {
  const UpdatePlayerLifeEvent({
    required this.playerNumber,
    required this.decrement,
  });
  final int playerNumber;

  final bool decrement;
}

class UpdatePlayerLifeByXEvent extends PlayerEvent {
  const UpdatePlayerLifeByXEvent({
    required this.playerNumber,
    required this.decrement,
  });
  final int playerNumber;
  final bool decrement;
}

class PlayerStopDecrement extends PlayerEvent {}

class PlayerDiesEvent extends PlayerEvent {
  const PlayerDiesEvent({required this.playerNumber});

  final int playerNumber;
}
