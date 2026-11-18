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
    this.gameTags = const [],
    this.hasSuggestedTags = false,
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

  /// Ids of the tags for the whole game. Player tags live on each player in
  /// [standings], so they follow the player when the standings change.
  final List<String> gameTags;

  /// Whether the app selected some tags from the game data when the screen
  /// opened. The view then explains why tags are already selected.
  final bool hasSuggestedTags;

  GameOverState copyWith({
    List<Player>? standings,
    GameModel? gameModel,
    String? selectedPlayerId,
    String? firstPlayerId,
    GameOverStatus? status,
    GameOverExitIntent? exitIntent,
    List<String>? gameTags,
  }) {
    return GameOverState(
      standings: standings ?? this.standings,
      gameModel: gameModel ?? this.gameModel,
      selectedPlayerId: selectedPlayerId ?? this.selectedPlayerId,
      firstPlayerId: firstPlayerId ?? this.firstPlayerId,
      status: status ?? this.status,
      exitIntent: exitIntent ?? this.exitIntent,
      gameTags: gameTags ?? this.gameTags,
      hasSuggestedTags: hasSuggestedTags,
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
    gameTags,
    hasSuggestedTags,
  ];
}
