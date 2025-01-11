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
    this.cardList,
  });

  final PlayerCustomizationStatus status;
  final String name;
  final Commander? commander;
  final SearchCards? cardList;

  @override
  List<Object?> get props => [status, name, commander, cardList];

  PlayerCustomizationState copyWith({
    PlayerCustomizationStatus? status,
    String? name,
    Commander? commander,
    SearchCards? cardList,
  }) {
    return PlayerCustomizationState(
      status: status ?? this.status,
      name: name ?? this.name,
      commander: commander ?? this.commander,
      cardList: cardList ?? this.cardList,
    );
  }
}
