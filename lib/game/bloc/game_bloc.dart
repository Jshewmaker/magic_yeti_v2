import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:magic_yeti/player/player.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({
    required FirebaseDatabaseRepository firebase,
  })  : _firebase = firebase,
        super(const GameState()) {
    on<CreateGameEvent>(_onCreateGame);
    on<UpdatePlayerEvent>(_onUpdatePlayer);
    // on<UpdatePlayerEvent>(_onUpdatePlayerLifeTotal);
    on<GameOverEvent>(_onGameOver);
    on<GameResetEvent>(_onGameReset);
  }
  final FirebaseDatabaseRepository _firebase;
  final deadPlayerList = <Player>[];
  Future<void> _onCreateGame(
    CreateGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameStatus.loading));
    final playerList = <Player>[];
    for (var i = 0; i < event.numberOfPlayers; ++i) {
      playerList.add(
        Player(
          id: UniqueKey().hashCode,
          color: (math.Random().nextDouble() * 0xFFFFFF).toInt(),
          name: 'Player ${playerList.length + 1}',
          picture: '',
          playerNumber: playerList.length,
          lifePoints: 40,
        ),
      );
    }
    emit(state.copyWith(status: GameStatus.idle, playerList: playerList));
  }

  Future<void> _onUpdatePlayer(
    UpdatePlayerEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameStatus.loading));

    state.playerList.removeWhere(
      (element) => element.id == event.player.id,
    );
    final updatedPlayer = event.player;
    if (updatedPlayer.lifePoints < 1) {
      updatedPlayer.copyWith(
        timeOfDeath: DateTime.now().toString(),
      );
    }
    if (_didPlayerDie(updatedPlayer)) {
      deadPlayerList.add(updatedPlayer);
    }

    if (deadPlayerList.length == state.playerList.length) {
      add(const GameOverEvent());
    } else {
      state.playerList.add(updatedPlayer);
      emit(
        state.copyWith(status: GameStatus.idle, playerList: state.playerList),
      );
    }
  }

  // void _onUpdatePlayerLifeTotal(
  //   UpdatePlayerEvent event,
  //   Emitter<GameState> emit,
  // ) {
  //   emit(state.copyWith(status: GameStatus.loading));
  //   var player = event.player;

  //   state.playerList.removeWhere((player) {
  //     return player.id == event.player.id;
  //   });
  //   switch (event.action) {
  //     case PlayerAction.increment:
  //       player.copyWith(lifePoints: player.lifePoints + 1);

  //     case PlayerAction.decrement:
  //       player = player.copyWith(lifePoints: player.lifePoints - 1);
  //     case PlayerAction.updateName:
  //       player = player.copyWith(name: event.player.name);
  //     case PlayerAction.updatePfP:
  //       player = player.copyWith(picture: event.player.picture);
  //   }

  //   if (player.lifePoints < 1) {
  //     player.copyWith(
  //       timeOfDeath: DateTime.now().toString(),
  //     );
  //   }
  //   emit(
  //     state.copyWith(
  //       status: GameStatus.idle,
  //       playerList: [
  //         ...state.playerList,
  //         player,
  //       ],
  //     ),
  //   );
  // }

  Future<void> _onGameOver(
    GameOverEvent event,
    Emitter<GameState> emit,
  ) async {
    try {
      final list = state.playerList.map((e) => e.toJson()).toList();
      await _firebase.saveGameStats(list);

      emit(
        state.copyWith(
          status: GameStatus.gameOver,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: GameStatus.failure));
    }
  }

  Future<void> _onGameReset(
    GameResetEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameStatus.loading));

    final updatedList = <Player>[];
    for (final player in state.playerList) {
      updatedList.add(
        player.copyWith(
          lifePoints: 40,
        ),
      );
    }
    emit(state.copyWith(status: GameStatus.idle, playerList: updatedList));
  }

  bool _didPlayerDie(Player player) {
    if (player.lifePoints < 1) {
      return true;
    }
    if (player.commanderDamageList.any((element) => element > 20)) {
      return true;
    }
    return false;
  }
}
