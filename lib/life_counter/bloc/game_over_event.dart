part of 'game_over_bloc.dart';

abstract class GameOverEvent extends Equatable {
  const GameOverEvent();

  @override
  List<Object?> get props => [];
}

class UpdateStandingsEvent extends GameOverEvent {
  const UpdateStandingsEvent({
    required this.oldIndex,
    required this.newIndex,
  });

  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class UpdateSelectedPlayerEvent extends GameOverEvent {
  const UpdateSelectedPlayerEvent(this.playerId);

  final String? playerId;

  @override
  List<Object?> get props => [playerId];
}

class UpdateFirstPlayerEvent extends GameOverEvent {
  const UpdateFirstPlayerEvent(this.playerId);

  final String? playerId;

  @override
  List<Object?> get props => [playerId];
}

/// Where the view should navigate after a successful save.
enum GameOverExitIntent { home, playAgain }

class SendGameOverStatsEvent extends GameOverEvent {
  const SendGameOverStatsEvent({
    required this.gameModel,
    required this.userId,
    this.exitIntent = GameOverExitIntent.home,
  });

  final GameModel? gameModel;
  final String userId;
  final GameOverExitIntent exitIntent;

  @override
  List<Object?> get props => [gameModel, userId, exitIntent];
}
