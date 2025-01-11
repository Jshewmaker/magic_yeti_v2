part of 'player_customization_bloc.dart';

sealed class PlayerCustomizationEvent extends Equatable {
  const PlayerCustomizationEvent();

  @override
  List<Object> get props => [];
}

final class CardListRequested extends PlayerCustomizationEvent {
  const CardListRequested({required this.cardName});

  final String cardName;

  @override
  List<Object> get props => [cardName];
}

final class UpdatePlayerName extends PlayerCustomizationEvent {
  const UpdatePlayerName({required this.name});

  final String name;

  @override
  List<Object> get props => [name];
}

final class UpdatePlayerCommander extends PlayerCustomizationEvent {
  const UpdatePlayerCommander({required this.commander});

  final Commander commander;

  @override
  List<Object> get props => [commander];
}
