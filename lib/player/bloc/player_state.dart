part of 'player_bloc.dart';

enum PlayerStatus {
  noPlayers,
  playerCreated,
  idle,
  updating,
  died,
}

final class PlayerState extends Equatable {
  const PlayerState({
    this.status = PlayerStatus.noPlayers,
    this.playerList = const <Player>[],
  });

  final PlayerStatus status;
  final List<Player> playerList;

  PlayerState copyWith({
    PlayerStatus? status,
    List<Player>? playerList,
  }) {
    return PlayerState(
      status: status ?? this.status,
      playerList: playerList ?? this.playerList,
    );
  }

  @override
  List<Object?> get props => [status];
}
