import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';

part 'match_history_event.dart';
part 'match_history_state.dart';

class MatchHistoryBloc extends Bloc<MatchHistoryEvent, MatchHistoryState> {
  MatchHistoryBloc({
    required FirebaseDatabaseRepository databaseRepository,
  })  : _databaseRepository = databaseRepository,
        super(const MatchHistoryState()) {
    // restartable: a new LoadMatchHistory cancels the previous Firestore
    // subscription instead of queueing behind it (the handler never
    // completes on its own because the games stream never closes).
    on<LoadMatchHistory>(_onLoadMatchHistory, transformer: restartable());
    on<AddMatchToPlayerHistoryEvent>(_addMatchToPlayerHistory);
  }

  final FirebaseDatabaseRepository _databaseRepository;

  Future<void> _onLoadMatchHistory(
    LoadMatchHistory event,
    Emitter<MatchHistoryState> emit,
  ) async {
    // An empty userId means "no signed-in user": clear any previous
    // history and stop listening.
    if (event.userId.isEmpty) {
      emit(
        state.copyWith(
          status: MatchHistoryStatus.loadingHistorySuccess,
          userId: '',
          games: const [],
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: MatchHistoryStatus.loadingHistory,
        userId: event.userId,
      ),
    );
    await emit.forEach(
      _databaseRepository.getGames(event.userId),
      onData: (List<GameModel> games) {
        // Sort games by end time in descending order (most recent first)
        final sortedGames = List<GameModel>.from(games)
          ..sort((a, b) => b.endTime.compareTo(a.endTime));

        return state.copyWith(
          status: MatchHistoryStatus.loadingHistorySuccess,
          games: sortedGames,
        );
      },
      onError: (error, stackTrace) {
        return state.copyWith(
          status: MatchHistoryStatus.failure,
          error: error.toString(),
        );
      },
    );
  }

  Future<void> _addMatchToPlayerHistory(
    AddMatchToPlayerHistoryEvent event,
    Emitter<MatchHistoryState> emit,
  ) async {
    try {
      // Reset a lingering gameNotFound status so a repeated failure produces
      // a new state (and a new toast) for listeners.
      emit(state.copyWith(status: MatchHistoryStatus.loadingHistorySuccess));
      final game = await _databaseRepository.getGame(event.roomId);
      await _databaseRepository.addMatchToPlayerHistory(game, event.playerId);
      // The games stream emits the updated history; no state change needed.
    } on GameNotFoundException catch (error) {
      emit(
        state.copyWith(
          status: MatchHistoryStatus.gameNotFound,
          error: error.toString(),
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: MatchHistoryStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }
}
