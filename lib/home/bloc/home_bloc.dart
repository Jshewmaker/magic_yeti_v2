import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required FirebaseDatabaseRepository databaseRepository,
  })  : _databaseRepository = databaseRepository,
        super(const HomeState()) {
    on<LoadMatchHistory>(_onLoadMatchHistory);
  }

  final FirebaseDatabaseRepository _databaseRepository;

  Future<void> _onLoadMatchHistory(
    LoadMatchHistory event,
    Emitter<HomeState> emit,
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
}
