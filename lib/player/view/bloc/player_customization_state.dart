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
    this.isAccountOwner = false,
  });

  final PlayerCustomizationStatus status;
  final String name;
  final Commander? commander;
  final Commander? partner;
  final SearchCards? cardList;
  final bool isAccountOwner;

  @override
  List<Object?> get props =>
      [status, name, commander, partner, cardList, isAccountOwner];

  PlayerCustomizationState copyWith({
    PlayerCustomizationStatus? status,
    String? name,
    Commander? Function()? commander,
    Commander? Function()? partner,
    SearchCards? cardList,
    bool? isAccountOwner,
  }) {
    return PlayerCustomizationState(
      status: status ?? this.status,
      name: name ?? this.name,
      commander: commander != null ? commander() : this.commander,
      partner: partner != null ? partner() : this.partner,
      cardList: cardList ?? this.cardList,
      isAccountOwner: isAccountOwner ?? this.isAccountOwner,
    );
  }
}
