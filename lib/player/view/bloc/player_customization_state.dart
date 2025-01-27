part of 'player_customization_bloc.dart';

enum PlayerCustomizationStatus {
  initial,
  loading,
  success,
  failure,
}

class PlayerCustomizationState extends Equatable {
  const PlayerCustomizationState({
    this.status = PlayerCustomizationStatus.initial,
    this.name = '',
    this.commander,
    this.partner,
    this.cardList,
    this.magicCardList,
    this.isAccountOwner = false,
    this.showOnlyLegendary = true,
    this.hasPartner = false,
    this.selectingPartner = false,
  });

  final PlayerCustomizationStatus status;
  final String name;
  final Commander? commander;
  final Commander? partner;
  final SearchCards? cardList;
  final List<MagicCard>? magicCardList;
  final bool isAccountOwner;
  final bool showOnlyLegendary;
  final bool hasPartner;
  final bool selectingPartner;

  @override
  List<Object?> get props => [
        status,
        name,
        commander,
        partner,
        cardList,
        magicCardList,
        isAccountOwner,
        showOnlyLegendary,
        hasPartner,
        selectingPartner,
      ];

  PlayerCustomizationState copyWith({
    PlayerCustomizationStatus? status,
    String? name,
    Commander? commander,
    Commander? partner,
    SearchCards? cardList,
    List<MagicCard>? filteredCards,
    bool? isAccountOwner,
    bool? showOnlyLegendary,
    bool? hasPartner,
    bool? selectingPartner,
  }) {
    return PlayerCustomizationState(
      status: status ?? this.status,
      name: name ?? this.name,
      commander: commander ?? this.commander,
      partner: partner ?? this.partner,
      cardList: cardList ?? this.cardList,
      magicCardList: filteredCards ?? this.magicCardList,
      isAccountOwner: isAccountOwner ?? this.isAccountOwner,
      showOnlyLegendary: showOnlyLegendary ?? this.showOnlyLegendary,
      hasPartner: hasPartner ?? this.hasPartner,
      selectingPartner: selectingPartner ?? this.selectingPartner,
    );
  }
}
