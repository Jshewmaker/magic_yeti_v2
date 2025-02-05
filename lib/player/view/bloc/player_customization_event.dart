part of 'player_customization_bloc.dart';

sealed class PlayerCustomizationEvent extends Equatable {
  const PlayerCustomizationEvent();

  @override
  List<Object?> get props => [];
}

final class CardListRequested extends PlayerCustomizationEvent {
  const CardListRequested({required this.cardName});

  final String cardName;

  @override
  List<Object> get props => [cardName];
}

final class UpdatePlayerCommander extends PlayerCustomizationEvent {
  const UpdatePlayerCommander({this.commander, this.partner});

  final Commander? commander;
  final Commander? partner;

  @override
  List<Object?> get props => [commander, partner];
}

final class ClearCardList extends PlayerCustomizationEvent {
  const ClearCardList();

  @override
  List<Object> get props => [];
}

final class UpdateAccountOwnership extends PlayerCustomizationEvent {
  const UpdateAccountOwnership({required this.isOwner});

  final bool isOwner;

  @override
  List<Object> get props => [isOwner];
}

final class UpdateCommanderFilters extends PlayerCustomizationEvent {
  const UpdateCommanderFilters({
    required this.showOnlyLegendary,
    required this.hasPartner,
  });

  final bool showOnlyLegendary;
  final bool hasPartner;

  @override
  List<Object> get props => [showOnlyLegendary, hasPartner];
}

final class UpdatePartnerSelection extends PlayerCustomizationEvent {
  const UpdatePartnerSelection({required this.selectingPartner});

  final bool selectingPartner;

  @override
  List<Object> get props => [selectingPartner];
}
