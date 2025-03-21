import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/models/player.dart' show Player;

part 'match_details_event.dart';
part 'match_details_state.dart';

class MatchDetailsBloc extends Bloc<MatchDetailsEvent, MatchDetailsState> {
  MatchDetailsBloc({
    required FirebaseDatabaseRepository databaseRepository,
  })  : _databaseRepository = databaseRepository,
        super(MatchDetailsInitial()) {
    on<DeleteMatchEvent>(_onDeleteMatch);
    on<UpdatePlayerOwnership>(_onUpdatePlayerOwnership);
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

  Future<void> _onUpdatePlayerOwnership(
    UpdatePlayerOwnership event,
    Emitter<MatchDetailsState> emit,
  ) async {
    try {
      // Update the players list, removing the Firebase ID from any player that had it
      // and assigning it to the selected player
      final updatedPlayers = event.game.players.map((p) {
        if (p.id == event.player.id) {
          // Assign the Firebase ID to the selected player
          return p.copyWith(firebaseId: () => event.currentUserFirebaseId);
        } else if (p.firebaseId == event.currentUserFirebaseId) {
          // Remove the Firebase ID from any other player that had it
          return p.copyWith(firebaseId: () => null);
        }
        return p;
      }).toList();

      // Update the game model with the new player list
      final updatedGame = event.game.copyWith(players: updatedPlayers);

      // Save the updated game to Firebase
      await _databaseRepository.updateGameStats(
        game: updatedGame,
        playerId: event.currentUserFirebaseId,
      );

      emit(MatchDetailsSuccess());
    } catch (error) {
      emit(MatchDetailsError(error.toString()));
    }
  }
}
