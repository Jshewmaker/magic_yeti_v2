import 'dart:math' as math;
import 'dart:ui';

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
    // on<PlayerDiesEvent>(_PlayerDiesEvent);
  }
  List<Player> playerList = [];
  Future<void> _onPlayerCreated(
    CreatePlayerEvent event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(status: PlayerStatus.noPlayers));
    for (var i = 0; i < event.numberOfPlayers; ++i) {
      playerList.add(
        Player(
          color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
              .withOpacity(1),
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

    emit(
      state.copyWith(
        status: PlayerStatus.idle,
        playerList: state.playerList,
      ),
    );
  }

  // void _PlayerDiesEvent(
  //   PlayerDiesEvent event,
  //   Emitter<PlayerState> emit,
  // ) {
  //   emit(state.copyWith(status: PlayerStatus.updating));

  //   final player = state.playerList
  //       .firstWhere((element) => element.playerNumber == event.playerNumber);
  //   state.playerList
  //       .removeWhere((element) => element.playerNumber == event.playerNumber);

  //   final update = event.decrement
  //       ? player.copyWith(lifePoints: player.lifePoints - 1)
  //       : player.copyWith(lifePoints: player.lifePoints + 1);
  //   state.playerList.add(update);
  //   state.playerList.sort((a, b) => a.playerNumber.compareTo(b.playerNumber));

  //   emit(
  //     state.copyWith(
  //       status: PlayerStatus.idle,
  //       playerList: state.playerList,
  //     ),
  //   );
  // }
}
