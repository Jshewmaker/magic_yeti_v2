import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/game_tags/game_tags.dart';
import 'package:player_repository/player_repository.dart';

part 'game_over_event.dart';
part 'game_over_state.dart';

class GameOverBloc extends Bloc<GameOverEvent, GameOverState> {
  GameOverBloc({
    required List<Player> players,
    required String currentUserId,
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
  }) : _firebaseDatabaseRepository = firebaseDatabaseRepository,
       super(_initialState(players, currentUserId)) {
    on<UpdateStandingsEvent>(_onUpdateStandings);
    on<UpdateSelectedPlayerEvent>(_onUpdateSelectedPlayer);
    on<UpdateFirstPlayerEvent>(_onUpdateFirstPlayer);
    on<ToggleGameTagEvent>(_onToggleGameTag);
    on<TogglePlayerTagEvent>(_onTogglePlayerTag);
    on<SendGameOverStatsEvent>(_onSendGameStatsToDatabase);
  }

  static GameOverState _initialState(
    List<Player> players,
    String currentUserId,
  ) {
    final sorted = List<Player>.from(players)
      ..sort((a, b) => a.placement.compareTo(b.placement));
    final standings = withSuggestedPlayerTags(sorted);
    final gameTags = suggestedGameTags(sorted);
    return GameOverState(
      standings: standings,
      selectedPlayerId: players
          .where((p) => p.firebaseId == currentUserId)
          .map((p) => p.id)
          .cast<String?>()
          .firstWhere((_) => true, orElse: () => null),
      firstPlayerId: null,
      gameTags: gameTags,
      hasSuggestedTags:
          gameTags.isNotEmpty || standings.any((p) => p.tags.isNotEmpty),
    );
  }

  /// Dropdown sentinel meaning the current user is not one of the players.
  static const notPlayingId = 'game_over_not_playing';

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
    emit(
      state.copyWith(standings: followFirstOut(state.standings, newStandings)),
    );
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

  void _onToggleGameTag(
    ToggleGameTagEvent event,
    Emitter<GameOverState> emit,
  ) {
    emit(state.copyWith(gameTags: event.tag.toggleIn(state.gameTags)));
  }

  void _onTogglePlayerTag(
    TogglePlayerTagEvent event,
    Emitter<GameOverState> emit,
  ) {
    emit(
      state.copyWith(
        standings: [
          for (final player in state.standings)
            if (player.id == event.playerId)
              player.copyWith(tags: event.tag.toggleIn(player.tags))
            else
              player,
        ],
      ),
    );
  }

  Future<void> _onSendGameStatsToDatabase(
    SendGameOverStatsEvent event,
    Emitter<GameOverState> emit,
  ) async {
    // A second tap during the save round-trip must not create a second
    // game doc. The loading status is emitted synchronously below, before
    // this handler's first await, so any later submission started while a
    // save is in flight sees it here and bails. (A stream transformer like
    // droppable() would also work, but its cancellation semantics hang
    // bloc.close() when a save future never completes — e.g. in tests.)
    if (state.status == GameOverStatus.loading) return;
    if (event.gameModel == null) return;
    emit(
      state.copyWith(
        status: GameOverStatus.loading,
        exitIntent: event.exitIntent,
      ),
    );

    // Create a new game model with updated player placements and ownership
    final updatedGameModel = event.gameModel!.copyWith(
      hostId: event.userId,
      players: state.standings.asMap().entries.map((entry) {
        final index = entry.key;
        final player = entry.value;
        // Update player with new placement and firebase ID if selected
        return player.copyWith(
          placement: Value(index + 1),
          firebaseId: () {
            if (player.id == state.selectedPlayerId) {
              // Never clobber a slot already linked to another account
              // (PIN-linked friend); the UI excludes these, this guards it.
              if (player.firebaseId != null &&
                  player.firebaseId != event.userId) {
                return player.firebaseId;
              }
              return event.userId;
            }
            // The user disowned this slot by selecting a different one (or
            // notPlaying); unlink it so it doesn't stay tied to their
            // account. Foreign-linked slots are left untouched.
            if (player.firebaseId == event.userId) {
              return null;
            }
            return player.firebaseId;
          },
        );
      }).toList(),
      winnerId: state.standings.first.id,
      startingPlayerId: state.firstPlayerId,
      tags: state.gameTags,
    );

    try {
      await _firebaseDatabaseRepository.saveGameStats(updatedGameModel);
    } on Object catch (_) {
      emit(state.copyWith(status: GameOverStatus.failure));
      return;
    }

    // Fan-out to players' match histories happens server-side
    // (onGameCreated).

    emit(state.copyWith(status: GameOverStatus.success));
  }
}
