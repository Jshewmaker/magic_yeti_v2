import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:uuid/uuid.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({
    required PlayerRepository playerRepository,
    required FirebaseDatabaseRepository database,
  })  : _playerRepository = playerRepository,
        _database = database,
        super(const GameState()) {
    on<CreateGameEvent>(_onCreateGame);
    on<GameStartEvent>(_onGameStart);
    on<GamePauseEvent>(_onGamePause);
    on<GameResumeEvent>(_onGameResume);
    on<GameResetEvent>(_onGameReset);
    on<GameFinishEvent>(_onGameFinish);
    on<PlayerRepositoryUpdateEvent>(_repositoryUpdated);
    on<GameTimerTickEvent>(_onTimerTick);

    _playersSubscription = _playerRepository.players.listen((players) {
      add(PlayerRepositoryUpdateEvent(players: players));
    });
  }

  final PlayerRepository _playerRepository;
  final FirebaseDatabaseRepository _database;
  StreamSubscription<List<Player>>? _playersSubscription;
  Timer? _gameTimer;

  List<Player> get _players => _playerRepository.getPlayers();
  Future<void> _onCreateGame(
    CreateGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameState(status: GameStatus.loading));
    const uuid = Uuid();
    _playerRepository.clearPlayers();
    try {
      final uuidList =
          List.generate(event.numberOfPlayers, (index) => uuid.v4());
      for (var i = 0; i < event.numberOfPlayers; ++i) {
        final player = Player(
          id: uuidList[i],
          color: (math.Random().nextDouble() * 0xFFFFFF).toInt(),
          name: 'Player ${i + 1}',
          commander: const Commander(
            name: '',
            colors: [],
            cardType: '',
            imageUrl: '',
            manaCost: '',
            oracleText: '',
            artist: '',
          ),
          playerNumber: i,
          lifePoints: event.startingLifePoints,
          commanderDamageList: {for (final e in uuidList) e: 0},
        );
        _playerRepository.createPlayer(player);
      }
      add(const GameStartEvent());
    } catch (e) {
      emit(const GameState(status: GameStatus.error));
    }
  }

  void _onGameStart(
    GameStartEvent event,
    Emitter<GameState> emit,
  ) {
    _startTimer();
    emit(
      state.copyWith(
        status: GameStatus.running,
        playerList: _players,
        elapsedSeconds: 0,
        startTime: DateTime.now(),
      ),
    );
  }

  void _onGamePause(
    GamePauseEvent event,
    Emitter<GameState> emit,
  ) {
    _gameTimer?.cancel();
    emit(state.copyWith(status: GameStatus.paused));
  }

  void _onGameResume(
    GameResumeEvent event,
    Emitter<GameState> emit,
  ) {
    _startTimer();
    emit(state.copyWith(status: GameStatus.running));
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(GameTimerTickEvent(elapsedSeconds: state.elapsedSeconds + 1)),
    );
  }

  void _onTimerTick(
    GameTimerTickEvent event,
    Emitter<GameState> emit,
  ) {
    emit(
      state.copyWith(
        elapsedSeconds: event.elapsedSeconds,
      ),
    );
  }

  Future<void> _onGameReset(
    GameResetEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameStatus.loading));
    _gameTimer?.cancel();

    // Reset players
    for (final player in _players) {
      final resetPlayer = player.copyWith(
        lifePoints: _players.length == 4 ? 40 : 20,
        timeOfDeath: 0,
        placement: 99,
        commanderDamageList:
            Map.fromEntries(state.playerList.map((p) => MapEntry(p.id, 0))),
      );
      _playerRepository.updatePlayer(resetPlayer);
    }

    // Give time for the repository to update
    await Future<void>.delayed(const Duration(milliseconds: 100));

    add(const GameStartEvent());
  }

  void _onGameFinish(
    GameFinishEvent event,
    Emitter<GameState> emit,
  ) {
    _gameTimer?.cancel();

    final updateWinner = event.winner.copyWith(
      timeOfDeath: DateTime.now().millisecondsSinceEpoch,
      placement: 1,
    );
    _playerRepository.updatePlayer(updateWinner);
    _database.saveGameStats(
      GameModel(
        id: const Uuid().v4(),
        winner: updateWinner,
        players: _players,
        startTime: state.startTime ?? DateTime.now(),
        endTime: DateTime.now(),
        durationInSeconds: state.elapsedSeconds,
      ),
    );
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
    final alivePlayers = event.players.where((p) => p.lifePoints > 0).toList();
    if (alivePlayers.length == 1 && state.status == GameStatus.running) {
      add(GameFinishEvent(winner: alivePlayers.first));
    }
    emit(state.copyWith(playerList: event.players));
  }

  @override
  Future<void> close() {
    _playersSubscription?.cancel();
    _gameTimer?.cancel();
    return super.close();
  }
}
