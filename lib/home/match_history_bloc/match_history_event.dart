part of 'match_history_bloc.dart';

sealed class MatchHistoryEvent extends Equatable {
  const MatchHistoryEvent();

  @override
  List<Object> get props => [];
}

/// Event to (re)subscribe to a user's match history.
///
/// Passing an empty [userId] clears the history and cancels any active
/// subscription (used on sign-out).
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
