part of 'player_bloc.dart';

sealed class PlayerState extends Equatable {
  const PlayerState();
}

final class PlayerInitial extends PlayerState {
  const PlayerInitial();

  @override
  List<Object?> get props => [];
}

final class PlayerUpdating extends PlayerState {
  const PlayerUpdating();

  @override
  List<Object?> get props => [];
}

final class PlayerLifePointsUpdate extends PlayerState {
  const PlayerLifePointsUpdate({
    required this.player,
    required this.lifePoints,
  });

  final Player player;
  final int lifePoints;

  @override
  List<Object?> get props => [player, lifePoints];
}

final class PlayerUpdateName extends PlayerState {
  const PlayerUpdateName();

  @override
  List<Object?> get props => [];
}

final class PlayerUpdatePicture extends PlayerState {
  const PlayerUpdatePicture();

  @override
  List<Object?> get props => [];
}
