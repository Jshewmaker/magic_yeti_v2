import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/player_repository.dart';

part 'match_edit_state.dart';

class MatchEditCubit extends Cubit<MatchEditState> {
  MatchEditCubit({
    required FirebaseDatabaseRepository databaseRepository,
    required String currentUserId,
  })  : _databaseRepository = databaseRepository,
        _currentUserId = currentUserId,
        super(const MatchEditState());

  final FirebaseDatabaseRepository _databaseRepository;
  final String _currentUserId;

  GameModel? _game;

  void startEditing(GameModel game) {
    _game = game;
    emit(
      state.copyWith(
        status: MatchEditStatus.editing,
        draftPlayers: List<Player>.of(game.players),
      ),
    );
  }

  void cancel() {
    _game = null;
    emit(const MatchEditState());
  }

  void updateName(String playerId, String name) {
    emit(
      state.copyWith(
        draftPlayers: _replace(playerId, (p) => p.copyWith(name: name)),
      ),
    );
  }

  void setCommander(String playerId, Commander commander) {
    emit(
      state.copyWith(
        draftPlayers:
            _replace(playerId, (p) => p.copyWith(commander: commander)),
      ),
    );
  }

  void setPartner(String playerId, Commander? partner) {
    emit(
      state.copyWith(
        draftPlayers:
            _replace(playerId, (p) => p.copyWith(partner: () => partner)),
      ),
    );
  }

  Future<void> save() async {
    final game = _game;
    if (game == null) return;
    emit(state.copyWith(status: MatchEditStatus.saving));
    try {
      final updated = game.copyWith(players: state.draftPlayers);
      await _databaseRepository.updateGameStats(
        game: updated,
        playerId: _currentUserId,
      );
      _game = updated;
      emit(state.copyWith(status: MatchEditStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: MatchEditStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  List<Player> _replace(String playerId, Player Function(Player) update) {
    return state.draftPlayers
        .map((p) => p.id == playerId ? update(p) : p)
        .toList();
  }
}
