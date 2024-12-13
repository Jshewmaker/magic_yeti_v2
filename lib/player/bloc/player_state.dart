part of 'player_bloc.dart';

enum PlayerStatus {
  initial,
  updating,
  updated,
}

class PlayerState extends Equatable {
  const PlayerState({
    required this.status,
    required this.player,
    this.lifePoints,
  });

  final PlayerStatus status;
  final Player player;
  final int? lifePoints;

  PlayerState copyWith({
    PlayerStatus? status,
    Player? player,
    int? lifePoints,
  }) {
    return PlayerState(
      status: status ?? this.status,
      player: player ?? this.player,
      lifePoints: lifePoints ?? this.lifePoints,
    );
  }

  @override
  List<Object?> get props => [status, player, lifePoints];
}
