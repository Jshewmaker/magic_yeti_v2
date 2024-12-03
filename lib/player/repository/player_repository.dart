import 'dart:async';
import 'package:magic_yeti/player/player.dart';

class PlayerRepository {
  PlayerRepository() {
    _playerController = StreamController<List<Player>>.broadcast();
  }

  late final StreamController<List<Player>> _playerController;
  final List<Player> _players = [];

  Stream<List<Player>> get players => _playerController.stream;

  void updatePlayer(Player player) {
    final index = _players.indexWhere((p) => p.id == player.id);
    if (index != -1) {
      _players[index] = player;
    } else {
      _players.add(player);
    }
    _playerController.add(_players);
  }

  List<Player> getPlayers() => List.unmodifiable(_players);

  Player getPlayerById(int id) {
    return _players.firstWhere((player) => player.id == id);
  }

  void dispose() {
    _playerController.close();
  }
}
