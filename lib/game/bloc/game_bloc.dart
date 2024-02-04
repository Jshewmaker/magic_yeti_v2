import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc() : super(GameInitial()) {
    on<GameOverEvent>(_onGameOver);
  }
  Future<void> _onGameOver(
    GameOverEvent event,
    Emitter<GameState> emit,
  ) async {}
}
