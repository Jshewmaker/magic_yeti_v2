part of 'match_details_bloc.dart';

sealed class MatchDetailsEvent extends Equatable {
  const MatchDetailsEvent();

  @override
  List<Object> get props => [];
}

final class DeleteMatchEvent extends MatchDetailsEvent {
  const DeleteMatchEvent({required this.gameId, required this.userId});
  final String gameId;
  final String userId;

  @override
  List<Object> get props => [gameId, userId];
}

/// Event to update player ownership in a game
final class UpdatePlayerOwnership extends MatchDetailsEvent {
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
