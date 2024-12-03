import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/repository/player_repository.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({
    required FirebaseDatabaseRepository firebase,
    required PlayerRepository playerRepository,
  })  : _firebase = firebase,
        _playerRepository = playerRepository,
        super(const GameInitial()) {
    on<CreateGameEvent>(_onCreateGame);
    on<GameOverEvent>(_onGameOver);
    on<GameResetEvent>(_onGameReset);
    on<PlayersUpdatedEvent>(_onPlayersUpdated);

    // Subscribe to player repository updates
    _playerSubscription = _playerRepository.players.listen((players) {
      add(PlayersUpdatedEvent(players: players));
    });
  }

  final FirebaseDatabaseRepository _firebase;
  final PlayerRepository _playerRepository;
  late final StreamSubscription<List<Player>> _playerSubscription;
  List<Player> _players = [];

  @override
  Future<void> close() {
    _playerSubscription.cancel();
    return super.close();
  }

  void _onPlayersUpdated(
    PlayersUpdatedEvent event,
    Emitter<GameState> emit,
  ) {
    final players = event.players;
    _players = players;

    if (players.isEmpty) {
      emit(const GameInitial());
      return;
    }

    final alivePlayers = players.where((p) => p.timeOfDeath.isEmpty).toList();

    if (alivePlayers.length == 1 && players.length > 1) {
      emit(
        GameFinished(
          playerList: players,
          winner: alivePlayers.first,
        ),
      );
    } else {
      emit(GameRunning(playerList: players));
    }
  }

  Future<void> _onCreateGame(
    CreateGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameLoading());

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
    } catch (e) {
      emit(GameError(error: e.toString()));
    }
  }

  Future<void> _onGameOver(
    GameOverEvent event,
    Emitter<GameState> emit,
  ) async {
    final alivePlayers = _players.where((p) => p.timeOfDeath.isEmpty).toList();

    if (alivePlayers.length == 1) {
      emit(
        GameFinished(
          playerList: _players,
          winner: alivePlayers.first,
        ),
      );
    }
  }

  Future<void> _onGameReset(
    GameResetEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameInitial());
    // Clear the repository
    for (final player in _players) {
      _playerRepository.updatePlayer(
        player.copyWith(
          lifePoints: 40,
          timeOfDeath: '',
        ),
      );
    }
  }
}
