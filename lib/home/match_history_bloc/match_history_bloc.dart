import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';

part 'match_history_event.dart';
part 'match_history_state.dart';

class MatchHistoryBloc extends Bloc<MatchHistoryEvent, MatchHistoryState> {
  MatchHistoryBloc({
    required FirebaseDatabaseRepository databaseRepository,
  })  : _databaseRepository = databaseRepository,
        super(const MatchHistoryState()) {
    on<LoadMatchHistory>(_onLoadMatchHistory);
    on<ClearMatchHistory>(_onClearMatchHistory);
    on<AddMatchToPlayerHistoryEvent>(_addMatchToPlayerHistory);
  }

  final FirebaseDatabaseRepository _databaseRepository;

  Future<void> _onLoadMatchHistory(
    LoadMatchHistory event,
    Emitter<MatchHistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: MatchHistoryStatus.loadingHistory,
        userId: event.userId,
      ),
    );
    if (event.userId.isEmpty) return;
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
      final game = await _databaseRepository.getGame(event.roomId);
      await _databaseRepository.addMatchToPlayerHistory(game, event.playerId);
      emit(
        state.copyWith(
          status: MatchHistoryStatus.loadingHistorySuccess,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: MatchHistoryStatus.gameNotFound,
          error: error.toString(),
        ),
      );
    }
  }

  void _onClearMatchHistory(
    ClearMatchHistory event,
    Emitter<MatchHistoryState> emit,
  ) {
    emit(
      state.copyWith(
        status: MatchHistoryStatus.loadingHistorySuccess,
        games: const [],
      ),
    );
  }
}
