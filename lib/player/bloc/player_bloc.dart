import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:magic_yeti/player/player.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc() : super(const PlayerState()) {
    on<CreatePlayerEvent>(_onPlayerCreated);
    on<UpdateCommanderEvent>(_onCommanderUpdated);
    on<UpdatePlayerNameEvent>(_updatePlayerName);
    on<UpdatePlayerLifeEvent>(_updatePlayerLifeTotal);
    on<UpdatePlayerLifeByXEvent>(_updatePlayerLifeTotalByX);
    on<PlayerStopDecrement>(_onStopDecrementing);
  }
  List<Player> playerList = [];
  Timer? _timer;

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  Future<void> _onPlayerCreated(
    CreatePlayerEvent event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(status: PlayerStatus.noPlayers));
    for (var i = 0; i < event.numberOfPlayers; ++i) {
      playerList.add(
        Player(
          color: (math.Random().nextDouble() * 0xFFFFFF).toInt(),
          name: 'Player ${playerList.length}',
          picture: '',
          playerNumber: playerList.length,
          lifePoints: 40,
        ),
      );
    }

    emit(
      state.copyWith(
        status: PlayerStatus.idle,
        playerList: playerList,
      ),
    );
  }

  void _onCommanderUpdated(
    UpdateCommanderEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.updating));
    final player = state.playerList
        .firstWhere((element) => element.playerNumber == event.playerNumber);
    state.playerList
        .removeWhere((element) => element.playerNumber == event.playerNumber);

    final update = player.copyWith(picture: event.pictureUrl);
    state.playerList.add(update);
    state.playerList.sort((a, b) => a.playerNumber.compareTo(b.playerNumber));

    emit(
      state.copyWith(
        status: PlayerStatus.idle,
        playerList: state.playerList,
      ),
    );
  }

  void _updatePlayerName(
    UpdatePlayerNameEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.updating));
    playerList[event.playerNumber].copyWith(
      name: event.name,
    );

    final player = state.playerList
        .firstWhere((element) => element.playerNumber == event.playerNumber);
    state.playerList
        .removeWhere((element) => element.playerNumber == event.playerNumber);

    final update = player.copyWith(name: event.name);
    state.playerList.add(update);
    state.playerList.sort((a, b) => a.playerNumber.compareTo(b.playerNumber));

    emit(
      state.copyWith(
        status: PlayerStatus.idle,
        playerList: state.playerList,
      ),
    );
  }

  void _updatePlayerLifeTotal(
    UpdatePlayerLifeEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.updating));

    final player = state.playerList
        .firstWhere((element) => element.playerNumber == event.playerNumber);
    state.playerList
        .removeWhere((element) => element.playerNumber == event.playerNumber);

    final update = event.decrement
        ? player.copyWith(lifePoints: player.lifePoints - 1)
        : player.copyWith(lifePoints: player.lifePoints + 1);
    state.playerList.add(update);
    state.playerList.sort((a, b) => a.playerNumber.compareTo(b.playerNumber));
    if (update.lifePoints < 1) {
      emit(
        state.copyWith(
          status: PlayerStatus.died,
          playerList: state.playerList,
        ),
      );
    }
    emit(
      state.copyWith(
        status: PlayerStatus.idle,
        playerList: state.playerList,
      ),
    );
  }

  void _updatePlayerLifeTotalByX(
    UpdatePlayerLifeByXEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.updating));

    final player = state.playerList
        .firstWhere((element) => element.playerNumber == event.playerNumber);
    state.playerList
        .removeWhere((element) => element.playerNumber == event.playerNumber);

    final update = event.decrement
        ? player.copyWith(lifePoints: player.lifePoints - 10)
        : player.copyWith(lifePoints: player.lifePoints + 10);
    state.playerList.add(update);
    state.playerList.sort((a, b) => a.playerNumber.compareTo(b.playerNumber));
    emit(
      state.copyWith(
        status: PlayerStatus.idle,
        playerList: state.playerList,
      ),
    );
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      add(
        UpdatePlayerLifeByXEvent(
          playerNumber: event.playerNumber,
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
    emit(
      state.copyWith(
        status: PlayerStatus.idle,
        playerList: state.playerList,
      ),
    );
  }
}
