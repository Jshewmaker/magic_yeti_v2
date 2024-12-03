import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/repository/player_repository.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
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
  int? _currentDecrementingPlayerId;

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
    final player = _playerRepository.getPlayerById(event.playerId);

    if (event.pictureUrl != null) {
      final updatedPlayer = player.copyWith(picture: event.pictureUrl);
      _playerRepository.updatePlayer(updatedPlayer);
      emit(const PlayerUpdatePicture());
    }

    if (event.playerName != null) {
      final updatedPlayer = player.copyWith(name: event.playerName);
      _playerRepository.updatePlayer(updatedPlayer);
      emit(const PlayerUpdateName());
    }
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

    _currentDecrementingPlayerId = event.playerId;
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
    _currentDecrementingPlayerId = null;
  }
}
