import 'dart:async';
import 'dart:math';

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
    on<GameUpdatePlayerOwnershipEvent>(_onUpdatePlayerOwnership);

    _playersSubscription = _playerRepository.players.listen((players) {
      add(PlayerRepositoryUpdateEvent(players: players));
    });
  }

  final PlayerRepository _playerRepository;
  final FirebaseDatabaseRepository _database;
  StreamSubscription<List<Player>>? _playersSubscription;
  Timer? _gameTimer;

  List<Player> get _players => _playerRepository.getPlayers();

  // Predefined list of visually pleasing colors
  final _playerColors = [
    0xFF1ABC9C, // Turquoise
    0xFF3498DB, // Blue
    0xFF9B59B6, // Purple
    0xFFE74C3C, // Red
    0xFFF1C40F, // Yellow
    0xFF2ECC71, // Green
    0xFFE67E22, // Orange
    0xFF34495E, // Navy Blue
    0xFFD35400, // Burnt Orange
    0xFF27AE60, // Emerald
    0xFF8E44AD, // Violet
    0xFFC0392B, // Dark Red
    0xFF16A085, // Sea Green
    0xFF2980B9, // Ocean Blue
    0xFFD35400, // Pumpkin
    0xFF7F8C8D, // Gray
    0xFF8E44AD, // Wisteria
    0xFFf39c12, // Carrot
    0xFF2C3E50, // Midnight Blue
    0xFF16A085, // Green Sea
  ];

  Future<void> _onCreateGame(
    CreateGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameStatus.loading));
    const uuid = Uuid();
    _playerRepository.clearPlayers();
    try {
      final uuidList =
          List.generate(event.numberOfPlayers, (index) => uuid.v4());
      // Create a shuffled copy of the colors list
      final shuffledColors = List<int>.from(_playerColors)..shuffle();
      for (var i = 0; i < event.numberOfPlayers; ++i) {
        final player = Player(
          id: uuidList[i],
          color: shuffledColors[i],
          name: 'Player ${i + 1}',
          playerNumber: i,
          lifePoints: event.startingLifePoints,
          commanderDamageList: {for (final e in uuidList) e: 0},
        );
        _playerRepository.createPlayer(player);
      }
      add(const GameStartEvent());
    } catch (e) {
      emit(
        state.copyWith(
          status: GameStatus.error,
          error: '[CreateGameEvent] $e',
        ),
      );
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
    try {
      for (final player in _players) {
        final resetPlayer = player.copyWith(
          lifePoints: _players.length == 4 ? 40 : 20,
          timeOfDeath: const Value(null),
          placement: const Value(null),
          state: PlayerModelState.active,
          commanderDamageList:
              Map.fromEntries(state.playerList.map((p) => MapEntry(p.id, 0))),
        );
        _playerRepository.updatePlayer(resetPlayer);
      }

      // Give time for the repository to update
      await Future<void>.delayed(const Duration(milliseconds: 100));

      add(const GameStartEvent());
    } catch (e) {
      emit(
        state.copyWith(
          status: GameStatus.error,
          error: '[GameResetEvent] $e',
        ),
      );
    }
  }

  Future<void> _onGameFinish(
    GameFinishEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameStatus.loading));
    _gameTimer?.cancel();

    final updateWinner = event.winner.copyWith(
      placement: const Value(1),
      lifePoints: 0,
      state: PlayerModelState.eliminated,
      timeOfDeath: Value(DateTime.now().millisecondsSinceEpoch),
    );

    _playerRepository.updatePlayer(updateWinner);

    final gameModel = GameModel(
      roomId: await generateShortGameId(),
      id: const Uuid().v4(),
      winner: updateWinner,
      players: state.playerList,
      startTime: state.startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      durationInSeconds: state.elapsedSeconds,
    );

    emit(
      state.copyWith(status: GameStatus.finished, gameModel: gameModel),
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

  Future<void> _onUpdatePlayerOwnership(
    GameUpdatePlayerOwnershipEvent event,
    Emitter<GameState> emit,
  ) async {
    try {
      final updateWinner = state.playerList.firstWhere(
        (player) => player.placement == 1,
      );
      final gameModel = GameModel(
        roomId: await generateShortGameId(),
        hostId: event.firebaseId,
        id: const Uuid().v4(),
        winner: updateWinner,
        players: state.playerList,
        startTime: state.startTime ?? DateTime.now(),
        endTime: DateTime.now(),
        durationInSeconds: state.elapsedSeconds,
      );

      emit(state.copyWith(gameModel: gameModel));
    } catch (e) {
      emit(state.copyWith(status: GameStatus.error, error: e.toString()));
    }
  }

  String _getRandomString(int length) {
    // Excluding similar looking characters
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }

  /// Generates a short, unique game ID
  /// Format: XXXX-YYYY where X is random chars and Y is sequential
  Future<String> generateShortGameId() async {
    var attempts = 0;
    const maxAttempts = 5;

    while (attempts < maxAttempts) {
      final gameId = _getRandomString(4);
      final exists = await _database.checkIfGameIdExists(gameId);

      if (!exists) {
        return gameId;
      }
      attempts++;
    }
    throw Exception('Failed to generate unique game ID');
  }

  @override
  Future<void> close() {
    _playersSubscription?.cancel();
    _gameTimer?.cancel();
    return super.close();
  }
}
