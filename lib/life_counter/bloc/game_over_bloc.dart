import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/player_repository.dart';

part 'game_over_event.dart';
part 'game_over_state.dart';

class GameOverBloc extends Bloc<GameOverEvent, GameOverState> {
  GameOverBloc({
    required List<Player> players,
    required GameModel gameModel,
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
  })  : _firebaseDatabaseRepository = firebaseDatabaseRepository,
        super(
          GameOverState(
            gameModel: gameModel,
            standings: List<Player>.from(players)
              ..sort((a, b) => a.placement.compareTo(b.placement)),
            selectedPlayerId: null,
            firstPlayerId: null,
          ),
        ) {
    on<UpdateStandingsEvent>(_onUpdateStandings);
    on<UpdateSelectedPlayerEvent>(_onUpdateSelectedPlayer);
    on<UpdateFirstPlayerEvent>(_onUpdateFirstPlayer);
    on<SendGameOverStatsEvent>(_onSendGameStatsToDatabase);
  }

  final FirebaseDatabaseRepository _firebaseDatabaseRepository;

  void _onUpdateStandings(
    UpdateStandingsEvent event,
    Emitter<GameOverState> emit,
  ) {
    final newStandings = List<Player>.from(state.standings);
    final player = newStandings.removeAt(event.oldIndex);
    if (event.oldIndex < event.newIndex) {
      newStandings.insert(event.newIndex - 1, player);
    } else {
      newStandings.insert(event.newIndex, player);
    }
    emit(state.copyWith(standings: newStandings));
  }

  void _onUpdateSelectedPlayer(
    UpdateSelectedPlayerEvent event,
    Emitter<GameOverState> emit,
  ) {
    emit(state.copyWith(selectedPlayerId: event.playerId));
  }

  void _onUpdateFirstPlayer(
    UpdateFirstPlayerEvent event,
    Emitter<GameOverState> emit,
  ) {
    emit(state.copyWith(firstPlayerId: event.playerId));
  }

  Future<void> _onSendGameStatsToDatabase(
    SendGameOverStatsEvent event,
    Emitter<GameOverState> emit,
  ) async {
    emit(state.copyWith(status: GameOverStatus.loading));
    if (event.gameModel == null) return;

    // Create a new game model with updated player placements and ownership
    final updatedGameModel = event.gameModel!.copyWith(
      hostId: event.userId,
      players: state.standings.asMap().entries.map((entry) {
        final index = entry.key;
        final player = entry.value;
        // Update player with new placement and firebase ID if selected
        return player.copyWith(
          placement: Value(index + 1),
          firebaseId: () => player.id == state.selectedPlayerId
              ? event.userId
              : player.firebaseId,
        );
      }).toList(),
      winnerId: state.standings.first.id,
      startingPlayerId: state.firstPlayerId,
    );

    await _firebaseDatabaseRepository.saveGameStats(updatedGameModel);

    await _firebaseDatabaseRepository.addMatchToPlayerHistory(
      updatedGameModel,
      event.userId,
    );

    emit(state.copyWith(status: GameOverStatus.success));
  }
}
