part of 'game_over_bloc.dart';

enum GameOverStatus { initial, loading, success, failure }

class GameOverState extends Equatable {
  const GameOverState({
    required this.standings,
    required this.selectedPlayerId,
    required this.firstPlayerId,
    this.gameModel,
    this.status = GameOverStatus.initial,
  });

  final List<Player> standings;
  final GameModel? gameModel;
  final String? selectedPlayerId;
  final String? firstPlayerId;
  final GameOverStatus status;

  GameOverState copyWith({
    List<Player>? standings,
    GameModel? gameModel,
    String? selectedPlayerId,
    String? firstPlayerId,
    GameOverStatus? status,
  }) {
    return GameOverState(
      standings: standings ?? this.standings,
      gameModel: gameModel ?? this.gameModel,
      selectedPlayerId: selectedPlayerId ?? this.selectedPlayerId,
      firstPlayerId: firstPlayerId ?? this.firstPlayerId,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [standings, selectedPlayerId, firstPlayerId];
}
