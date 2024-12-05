import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:player_repository/player_repository.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({
    required PlayerRepository playerRepository,
  })  : _playerRepository = playerRepository,
        super(const GameState()) {
    on<CreateGameEvent>(_onCreateGame);
    on<GameStartEvent>(_onGameStart);
    on<GameResetEvent>(_onGameReset);
    on<GameFinishEvent>(_onGameFinish);
  }

  final PlayerRepository _playerRepository;

  List<Player> get _players => _playerRepository.getPlayers();
  Future<void> _onCreateGame(
    CreateGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameState(status: GameStatus.loading));

    try {
      for (var i = 0; i < event.numberOfPlayers; ++i) {
        final player = Player(
          id: UniqueKey().hashCode,
          color: (math.Random().nextDouble() * 0xFFFFFF).toInt(),
          name: 'Player ${i + 1}',
          picture: '',
          playerNumber: i,
          lifePoints: 40,
        );
        _playerRepository.updatePlayer(player);
      }

      emit(
        state.copyWith(
          status: GameStatus.running,
          playerList: _players,
        ),
      );
    } catch (e) {
      emit(GameState(status: GameStatus.error, error: e.toString()));
    }
  }

  void _onGameStart(
    GameStartEvent event,
    Emitter<GameState> emit,
  ) {
    emit(
      state.copyWith(
        status: GameStatus.running,
        playerList: _players,
      ),
    );
  }

  Future<void> _onGameReset(
    GameResetEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameStatus.loading));

    // Reset players
    for (final player in _players) {
      final resetPlayer = player.copyWith(
        lifePoints: 40,
        timeOfDeath: '',
        placement: 99,
        commanderDamageList: [0, 0, 0, 0],
      );
      _playerRepository.updatePlayer(resetPlayer);
    }

    // Give time for the repository to update
    await Future<void>.delayed(const Duration(milliseconds: 100));

    emit(
      state.copyWith(
        status: GameStatus.initial,
        playerList: _players,
      ),
    );
  }

  void _onGameFinish(
    GameFinishEvent event,
    Emitter<GameState> emit,
  ) {
    emit(state.copyWith(
      status: GameStatus.finished,
      winner: event.winner,
    ));
  }
}
