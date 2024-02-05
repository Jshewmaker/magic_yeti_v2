import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/player/player.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({
    required FirebaseDatabaseRepository firebase,
  })  : _firebase = firebase,
        super(GameInitialState()) {
    on<GameOverEvent>(_onGameOver);
  }
  final FirebaseDatabaseRepository _firebase;
  Future<void> _onGameOver(
    GameOverEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(GameLoadingState());
    try {
      final list = event.player.map((e) => e.toJson()).toList();
      await _firebase.saveGameStats(list);

      emit(GameIdleState());
    } catch (e) {
      emit(GameFailureState());
    }
  }
}
