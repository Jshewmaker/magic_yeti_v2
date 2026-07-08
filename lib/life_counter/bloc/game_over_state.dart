part of 'game_over_bloc.dart';

enum GameOverStatus { initial, loading, success, failure }

class GameOverState extends Equatable {
  const GameOverState({
    required this.standings,
    required this.selectedPlayerId,
    required this.firstPlayerId,
    this.gameModel,
    this.status = GameOverStatus.initial,
    this.exitIntent = GameOverExitIntent.home,
  });

  final List<Player> standings;
  final GameModel? gameModel;
  final String? selectedPlayerId;
  final String? firstPlayerId;
  final GameOverStatus status;

  /// Where the view should navigate after a successful save. Set from the
  /// triggering [SendGameOverStatsEvent] so the view's listener knows the
  /// destination without needing to inspect the event directly.
  final GameOverExitIntent exitIntent;

  GameOverState copyWith({
    List<Player>? standings,
    GameModel? gameModel,
    String? selectedPlayerId,
    String? firstPlayerId,
    GameOverStatus? status,
    GameOverExitIntent? exitIntent,
  }) {
    return GameOverState(
      standings: standings ?? this.standings,
      gameModel: gameModel ?? this.gameModel,
      selectedPlayerId: selectedPlayerId ?? this.selectedPlayerId,
      firstPlayerId: firstPlayerId ?? this.firstPlayerId,
      status: status ?? this.status,
      exitIntent: exitIntent ?? this.exitIntent,
    );
  }

  @override
  List<Object?> get props => [
    standings,
    selectedPlayerId,
    firstPlayerId,
    gameModel,
    status,
    exitIntent,
  ];
}
