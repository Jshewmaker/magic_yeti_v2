import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:magic_yeti/player/player.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc() : super(const PlayerState()) {
    on<UpdatePlayerInfoEvent>(_onPlayerInfoUpdate);
    on<UpdatePlayerLifeEvent>(_updatePlayerLifeTotal);
    on<UpdatePlayerLifeByXEvent>(_updatePlayerLifeTotalByX);
    on<PlayerStopDecrement>(_onStopDecrementing);
    on<PlayerEventReset>(_onReset);
  }

  Timer? _timer;

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void _onReset(
    PlayerEventReset event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.idle));
  }

  void _onPlayerInfoUpdate(
    UpdatePlayerInfoEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.idle, player: event.player));
  }

  void _updatePlayerLifeTotal(
    UpdatePlayerLifeEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.updating));

    final player = event.decrement
        ? event.player.copyWith(lifePoints: event.player.lifePoints - 1)
        : event.player.copyWith(lifePoints: event.player.lifePoints + 1);
    if (player.lifePoints < 1) {
      emit(
        state.copyWith(
          player: player.copyWith(
            timeOfDeath: DateTime.now().toString(),
          ),
        ),
      );
    } else {
      emit(state.copyWith(status: PlayerStatus.idle, player: player));
    }
  }

  void _updatePlayerLifeTotalByX(
    UpdatePlayerLifeByXEvent event,
    Emitter<PlayerState> emit,
  ) {
    final player = event.decrement
        ? event.player.copyWith(lifePoints: event.player.lifePoints - 10)
        : event.player.copyWith(lifePoints: event.player.lifePoints + 10);

    emit(state.copyWith(status: PlayerStatus.idle, player: player));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      add(
        UpdatePlayerLifeByXEvent(
          player: player,
          decrement: event.decrement,
        ),
      );
    });
  }

  void _onStopDecrementing(
    PlayerStopDecrement event,
    Emitter<PlayerState> emit,
  ) {
    _timer?.cancel();
    emit(state.copyWith(status: PlayerStatus.idle, player: event.player));
  }
}
