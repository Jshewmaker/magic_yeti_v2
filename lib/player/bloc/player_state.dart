part of 'player_bloc.dart';

enum PlayerStatus {
  idle,
  updating,
  died,
}

final class PlayerState extends Equatable {
  const PlayerState({
    required this.player,
    this.status = PlayerStatus.idle,
  });

  final PlayerStatus status;
  final Player player;

  PlayerState copyWith({
    PlayerStatus? status,
    Player? player,
  }) {
    return PlayerState(
      status: status ?? this.status,
      player: player ?? this.player,
    );
  }

  @override
  List<Object?> get props => [status];
}
