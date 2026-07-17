import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/models/player.dart' show Player;

part 'match_details_event.dart';
part 'match_details_state.dart';

class MatchDetailsBloc extends Bloc<MatchDetailsEvent, MatchDetailsState> {
  MatchDetailsBloc({
    required FirebaseDatabaseRepository databaseRepository,
  }) : _databaseRepository = databaseRepository,
       super(MatchDetailsInitial()) {
    on<DeleteMatchEvent>(_onDeleteMatch);
    on<AssignSeatIdentity>(_onAssignSeatIdentity);
  }

  final FirebaseDatabaseRepository _databaseRepository;

  Future<void> _onDeleteMatch(
    DeleteMatchEvent event,
    Emitter<MatchDetailsState> emit,
  ) async {
    try {
      emit(MatchDetailsDeleted());
      await _databaseRepository.deleteGame(event.gameId, event.userId);
    } catch (e) {
      emit(MatchDetailsError(e.toString()));
    }
  }

  Future<void> _onAssignSeatIdentity(
    AssignSeatIdentity event,
    Emitter<MatchDetailsState> emit,
  ) async {
    try {
      final assignedId = event.assignedFirebaseId;

      // Place the identity on the chosen seat and strip it from any other seat
      // that held it, so one account never occupies two seats.
      final updatedPlayers = event.game.players.map((p) {
        if (p.id == event.seat.id) {
          return p.copyWith(firebaseId: () => assignedId);
        }
        if (assignedId != null && p.firebaseId == assignedId) {
          return p.copyWith(firebaseId: () => null);
        }
        return p;
      }).toList();

      final updatedGame = event.game.copyWith(players: updatedPlayers);

      // Written to the owner's own history copy only.
      await _databaseRepository.updateGameStats(
        game: updatedGame,
        playerId: event.ownerUserId,
      );

      emit(MatchDetailsSuccess());
    } on Object catch (error) {
      emit(MatchDetailsError(error.toString()));
    }
  }
}
