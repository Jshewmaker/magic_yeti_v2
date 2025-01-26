part of 'match_history_bloc.dart';

sealed class MatchHistoryEvent extends Equatable {
  const MatchHistoryEvent();

  @override
  List<Object> get props => [];
}

/// Event to load match history
final class LoadMatchHistory extends MatchHistoryEvent {
  const LoadMatchHistory({
    required this.userId,
  });

  final String userId;

  @override
  List<Object> get props => [userId];
}

/// Event to add a match to the player's history
final class AddMatchToPlayerHistoryEvent extends MatchHistoryEvent {
  const AddMatchToPlayerHistoryEvent({
    required this.roomId,
    required this.playerId,
  });

  final String roomId;
  final String playerId;

  @override
  List<Object> get props => [roomId, playerId];
}

/// Event to clear match history
final class ClearMatchHistory extends MatchHistoryEvent {
  const ClearMatchHistory();
}

/// Event to compile match history
final class CompileMatchHistoryData extends MatchHistoryEvent {
  const CompileMatchHistoryData();
}

/// Event to update player ownership in a game
final class UpdatePlayerOwnership extends MatchHistoryEvent {
  const UpdatePlayerOwnership({
    required this.game,
    required this.player,
    required this.currentUserFirebaseId,
  });

  final GameModel game;
  final Player player;
  final String currentUserFirebaseId;

  @override
  List<Object> get props => [game, player, currentUserFirebaseId];
}
