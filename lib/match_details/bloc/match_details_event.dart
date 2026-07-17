part of 'match_details_bloc.dart';

sealed class MatchDetailsEvent extends Equatable {
  const MatchDetailsEvent();

  @override
  List<Object?> get props => [];
}

final class DeleteMatchEvent extends MatchDetailsEvent {
  const DeleteMatchEvent({required this.gameId, required this.userId});
  final String gameId;
  final String userId;

  @override
  List<Object> get props => [gameId, userId];
}

/// Assigns an account identity to a seat in a saved game.
///
/// [assignedFirebaseId] is the account to place on [seat] — the signed-in user,
/// a friend, or null to unassign. Whichever identity is assigned is removed
/// from any other seat that held it, so one account never occupies two seats.
///
/// The edit is written to [ownerUserId]'s own history copy only; tagging a
/// friend is a private annotation on the user's records that the friend never
/// sees.
final class AssignSeatIdentity extends MatchDetailsEvent {
  const AssignSeatIdentity({
    required this.game,
    required this.seat,
    required this.assignedFirebaseId,
    required this.ownerUserId,
  });

  final GameModel game;
  final Player seat;
  final String? assignedFirebaseId;
  final String ownerUserId;

  @override
  List<Object?> get props => [game, seat, assignedFirebaseId, ownerUserId];
}
