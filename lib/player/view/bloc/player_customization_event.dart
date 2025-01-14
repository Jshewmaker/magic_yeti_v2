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

final class UpdatePlayerCommander extends PlayerCustomizationEvent {
  const UpdatePlayerCommander({required this.commander});

  final Commander commander;

  @override
  List<Object> get props => [commander];
}

final class UpdateAccountOwnership extends PlayerCustomizationEvent {
  const UpdateAccountOwnership({required this.isOwner});

  final bool isOwner;

  @override
  List<Object> get props => [isOwner];
}
