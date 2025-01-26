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
    required String playerId,
  })  : _playerRepository = playerRepository,
        _playerId = playerId,
        super(
          PlayerState(
            player: playerRepository.getPlayerById(playerId),
          ),
        ) {
    on<UpdatePlayerInfoEvent>(_onPlayerInfoUpdate);
    on<UpdatePlayerLifeEvent>(_updatePlayerLifeTotal);
    on<UpdatePlayerLifeByXEvent>(_updatePlayerLifeTotalByX);
    on<PlayerStopDecrement>(_onStopDecrementing);
    on<PlayerCommanderDamageIncremented>(_onTrackerIncremented);
    on<PlayerCommanderDamageDecremented>(_onTrackerDecremented);
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
  final String _playerId;
  StreamSubscription<Player>? _playerSubscription;
  Timer? _timer;

  @override
  Future<void> close() {
    _timer?.cancel();
    _playerSubscription?.cancel();
    return super.close();
  }

  void _onReset(
    PlayerEventReset event,
    Emitter<PlayerState> emit,
  ) {
    emit(
      PlayerState(
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
      commander: event.commander,
      name: event.playerName,
      firebaseId: () => event.firebaseId,
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
    emit(state.copyWith(status: PlayerStatus.updating));
    final player = _playerRepository.getPlayerById(event.playerId);
    final newLifePoints =
        event.decrement ? player.lifePoints - 1 : player.lifePoints + 1;

    final updatedPlayer = player.copyWith(lifePoints: newLifePoints);

    _playerRepository.updatePlayer(updatedPlayer);
    emit(
      state.copyWith(
        status: PlayerStatus.lifeTotalUpdated,
        player: updatedPlayer,
        lifePoints: newLifePoints,
      ),
    );
  }

  void _playerUpdatedByRepository(
    PlayerRepositoryUpdateEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.updating));
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
    emit(state.copyWith(status: PlayerStatus.updating));
    final player = _playerRepository.getPlayerById(event.playerId);
    final newLifePoints =
        event.decrement ? player.lifePoints - 10 : player.lifePoints + 10;

    final updatedPlayer = player.copyWith(lifePoints: newLifePoints);
    _playerRepository.updatePlayer(updatedPlayer);

    emit(
      state.copyWith(
        status: PlayerStatus.lifeTotalUpdated,
        player: updatedPlayer,
        lifePoints: newLifePoints,
      ),
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      add(
        UpdatePlayerLifeByXEvent(
          playerId: event.playerId,
          decrement: event.decrement,
        ),
      );
    });
  }

  void _onTrackerIncremented(
    PlayerCommanderDamageIncremented event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.updating));
    final player = _playerRepository.getPlayerById(_playerId);
    player.commanderDamageList[event.commanderId] =
        player.commanderDamageList[event.commanderId]! + 1;
    _playerRepository.updatePlayer(player);

    emit(
      state.copyWith(
        status: PlayerStatus.updated,
        player: player,
      ),
    );
  }

  void _onTrackerDecremented(
    PlayerCommanderDamageDecremented event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: PlayerStatus.updating));
    final player = _playerRepository.getPlayerById(_playerId);
    player.commanderDamageList[event.commanderId] =
        player.commanderDamageList[event.commanderId]! - 1;
    _playerRepository.updatePlayer(player);

    emit(
      state.copyWith(
        status: PlayerStatus.updated,
        player: player,
      ),
    );
  }

  void _onStopDecrementing(
    PlayerStopDecrement event,
    Emitter<PlayerState> emit,
  ) {
    _timer?.cancel();
  }
}
