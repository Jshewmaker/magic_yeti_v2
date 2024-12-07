import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:player_repository/player_repository.dart';
import 'package:uuid/uuid.dart';

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
    on<PlayerRepositoryUpdateEvent>(_repositoryUpdated);

    _playersSubscription = _playerRepository.players.listen((players) {
      add(PlayerRepositoryUpdateEvent(players: players));
    });
  }

  final PlayerRepository _playerRepository;
  StreamSubscription<List<Player>>? _playersSubscription;

  List<Player> get _players => _playerRepository.getPlayers();
  Future<void> _onCreateGame(
    CreateGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameState(status: GameStatus.loading));
    final uuid = const Uuid();

    try {
      final uuidList =
          List.generate(event.numberOfPlayers, (index) => uuid.v4());
      for (var i = 0; i < event.numberOfPlayers; ++i) {
        final player = Player(
          id: uuidList[i],
          color: (math.Random().nextDouble() * 0xFFFFFF).toInt(),
          name: 'Player ${i + 1}',
          picture: '',
          playerNumber: i,
          lifePoints: 40,
          commanderDamageList: {for (final e in uuidList) e: 0},
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
        commanderDamageList:
            Map.fromEntries(state.playerList.map((p) => MapEntry(p.id, 0))),
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
    emit(
      state.copyWith(
        status: GameStatus.finished,
        winner: event.winner,
      ),
    );
  }

  Future<void> _repositoryUpdated(
    PlayerRepositoryUpdateEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(
      state.copyWith(
        status: GameStatus.running,
        playerList: _players,
      ),
    );
  }

  @override
  Future<void> close() {
    _playersSubscription?.cancel();
    return super.close();
  }
}
