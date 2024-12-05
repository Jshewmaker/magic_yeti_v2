import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:player_repository/player_repository.dart';

part 'player_event.dart';
part 'player_state.dart';

/// {@template player_repository}
/// A repository that manages a list of players for a game.
///
/// This repository serves as the single source of truth for player data,
/// providing methods to create, read, update, and delete players, as well as
/// stream updates to player state.
///
/// Example:
/// ```dart
/// final repository = PlayerRepository();
///
/// // Add a new player
/// repository.updatePlayer(player);
///
/// // Get all players
/// final players = repository.getPlayers();
///
/// // Listen to player updates
/// repository.players.listen((players) {
///   // Handle player updates
/// });
/// ```
/// {@endtemplate}
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  /// {@macro player_repository}
  PlayerBloc({
    required PlayerRepository playerRepository,
    required int playerId,
  })  : _playerRepository = playerRepository,
        _playerId = playerId,
        super(
          PlayerState(
            status: PlayerStatus.updated,
            player: playerRepository.getPlayerById(playerId),
          ),
        ) {
    on<UpdatePlayerInfoEvent>(_onPlayerInfoUpdate);
    on<UpdatePlayerLifeEvent>(_updatePlayerLifeTotal);
    on<UpdatePlayerLifeByXEvent>(_updatePlayerLifeTotalByX);
    on<PlayerStopDecrement>(_onStopDecrementing);
    on<PlayerRepositoryUpdateEvent>(_playerUpdatedByRepository);
    on<PlayerEventReset>(_onReset);

    _playerSubscription = _playerRepository.players
        .map(
      (players) => players.firstWhere((player) => player.id == _playerId),
    )
        .listen((player) {
      if (player.id == _playerId) {
        add(PlayerRepositoryUpdateEvent(player: player));
      }
    });
  }

  final PlayerRepository _playerRepository;
  final int _playerId;
  StreamSubscription<Player>? _playerSubscription;
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
    emit(
      PlayerState(
        status: PlayerStatus.initial,
        player: _playerRepository.getPlayerById(_playerId),
      ),
    );
  }

  void _onPlayerInfoUpdate(
    UpdatePlayerInfoEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.updating));

    final player = _playerRepository.getPlayerById(event.playerId);
    final updatedPlayer = player.copyWith(
      picture: event.pictureUrl,
      name: event.playerName,
    );

    _playerRepository.updatePlayer(updatedPlayer);
    emit(
      state.copyWith(
        status: PlayerStatus.updated,
        player: updatedPlayer,
      ),
    );
  }

  void _updatePlayerLifeTotal(
    UpdatePlayerLifeEvent event,
    Emitter<PlayerState> emit,
  ) {
    final player = _playerRepository.getPlayerById(event.playerId);
    final newLifePoints =
        event.decrement ? player.lifePoints - 1 : player.lifePoints + 1;

    var updatedPlayer = player.copyWith(lifePoints: newLifePoints);

    if (newLifePoints < 1) {
      updatedPlayer = updatedPlayer.copyWith(
        timeOfDeath: DateTime.now().toString(),
      );
    }

    _playerRepository.updatePlayer(updatedPlayer);
    emit(
      state.copyWith(
        status: PlayerStatus.updated,
        player: updatedPlayer,
        lifePoints: newLifePoints,
      ),
    );
  }

  void _playerUpdatedByRepository(
    PlayerRepositoryUpdateEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(
      state.copyWith(
        status: PlayerStatus.updated,
        player: event.player,
        lifePoints: event.player.lifePoints,
      ),
    );
  }

  void _updatePlayerLifeTotalByX(
    UpdatePlayerLifeByXEvent event,
    Emitter<PlayerState> emit,
  ) {
    final player = _playerRepository.getPlayerById(event.playerId);
    final newLifePoints =
        event.decrement ? player.lifePoints - 10 : player.lifePoints + 10;

    final updatedPlayer = player.copyWith(lifePoints: newLifePoints);
    _playerRepository.updatePlayer(updatedPlayer);

    emit(
      state.copyWith(
        status: PlayerStatus.updated,
        player: updatedPlayer,
        lifePoints: newLifePoints,
      ),
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      add(
        UpdatePlayerLifeEvent(
          playerId: event.playerId,
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
  }
}
