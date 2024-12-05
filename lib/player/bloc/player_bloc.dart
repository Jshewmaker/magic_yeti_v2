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
  })  : _playerRepository = playerRepository,
        super(const PlayerInitial()) {
    on<UpdatePlayerInfoEvent>(_onPlayerInfoUpdate);
    on<UpdatePlayerLifeEvent>(_updatePlayerLifeTotal);
    on<UpdatePlayerLifeByXEvent>(_updatePlayerLifeTotalByX);
    on<PlayerStopDecrement>(_onStopDecrementing);
    on<PlayerEventReset>(_onReset);
  }

  final PlayerRepository _playerRepository;
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
    emit(const PlayerInitial());
  }

  void _onPlayerInfoUpdate(
    UpdatePlayerInfoEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(const PlayerUpdating());
    final player = _playerRepository.getPlayerById(event.playerId);

    final updatedPlayer =
        player.copyWith(picture: event.pictureUrl, name: event.playerName);
    _playerRepository.updatePlayer(updatedPlayer);
    emit(const PlayerUpdatePicture());

    // if (event.playerName != null) {
    //   final updatedPlayer = player.copyWith(name: event.playerName);
    //   _playerRepository.updatePlayer(updatedPlayer);
    //   emit(const PlayerUpdateName());
    // }
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
      updatedPlayer =
          updatedPlayer.copyWith(timeOfDeath: DateTime.now().toString());
    }

    _playerRepository.updatePlayer(updatedPlayer);
    emit(
      PlayerLifePointsUpdate(
        player: updatedPlayer,
        lifePoints: newLifePoints,
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
      PlayerLifePointsUpdate(
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
