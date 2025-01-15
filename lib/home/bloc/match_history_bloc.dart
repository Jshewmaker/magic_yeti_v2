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
  }

  final FirebaseDatabaseRepository _databaseRepository;

  Future<void> _onLoadMatchHistory(
    LoadMatchHistory event,
    Emitter<MatchHistoryState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    await emit.forEach(
      _databaseRepository.getGames(event.userId),
      onData: (List<GameModel> games) {
        // Sort games by end time in descending order (most recent first)
        final sortedGames = List<GameModel>.from(games)
          ..sort((a, b) => b.endTime.compareTo(a.endTime));

        return state.copyWith(
          status: HomeStatus.success,
          games: sortedGames,
        );
      },
      onError: (error, stackTrace) {
        return state.copyWith(
          status: HomeStatus.failure,
          error: error.toString(),
        );
      },
    );
  }

  void _onClearMatchHistory(
    ClearMatchHistory event,
    Emitter<MatchHistoryState> emit,
  ) {
    emit(state.copyWith(
      status: HomeStatus.success,
      games: const [],
    ));
  }
}
