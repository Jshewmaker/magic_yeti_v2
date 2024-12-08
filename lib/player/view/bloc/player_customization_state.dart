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
    this.cardList,
    this.name = '',
    this.imageURL = '',
  });

  final PlayerCustomizationStatus status;
  final SearchCards? cardList;
  final String name;
  final String imageURL;

  @override
  List<Object?> get props => [status, cardList, name, imageURL];

  PlayerCustomizationState copyWith({
    PlayerCustomizationStatus? status,
    SearchCards? cardList,
    String? name,
    String? imageURL,
  }) {
    return PlayerCustomizationState(
      status: status ?? this.status,
      cardList: cardList ?? this.cardList,
      name: name ?? this.name,
      imageURL: imageURL ?? this.imageURL,
    );
  }
}
