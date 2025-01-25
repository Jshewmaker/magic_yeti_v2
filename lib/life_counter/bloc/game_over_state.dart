part of 'game_over_bloc.dart';

enum GameOverStatus { initial, loading, success, failure }

class GameOverState extends Equatable {
  const GameOverState({
    required this.standings,
    required this.selectedPlayerId,
    required this.firstPlayerId,
    this.status = GameOverStatus.initial,
  });

  final List<Player> standings;
  final String? selectedPlayerId;
  final String? firstPlayerId;
  final GameOverStatus status;

  GameOverState copyWith({
    List<Player>? standings,
    String? selectedPlayerId,
    String? firstPlayerId,
    GameOverStatus? status,
  }) {
    return GameOverState(
      standings: standings ?? this.standings,
      selectedPlayerId: selectedPlayerId ?? this.selectedPlayerId,
      firstPlayerId: firstPlayerId ?? this.firstPlayerId,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [standings, selectedPlayerId, firstPlayerId];
}
