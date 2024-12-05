import 'dart:async';

import 'package:player_repository/models/player.dart';

/// {@template player_repository}
/// A repository for managing player data in the application.
///
/// This class provides methods to:
/// - Add and update players
/// - Retrieve players by ID
/// - Maintain a stream of players for reactive updates
///
/// The repository uses a [StreamController] to broadcast player list changes,
/// allowing multiple listeners to receive updates about the player collection.
/// {@endtemplate}
class PlayerRepository {
  /// {@macro player_repository}
  PlayerRepository() {
    _playerController = StreamController<List<Player>>.broadcast();
  }

  /// Internal stream controller for managing player list updates.
  late final StreamController<List<Player>> _playerController;

  /// Internal list of players.
  final List<Player> _players = [];

  /// A stream of player lists that can be listened to for updates.
  ///
  /// Provides real-time updates whenever the player list changes.
  Stream<List<Player>> get players => _playerController.stream;

  /// Updates an existing player or adds a new player to the repository.
  ///
  /// If a player with the same ID exists, it will be replaced.
  /// If no matching player is found, the player will be added to the list.
  ///
  /// [player] The player to update or add.
  void updatePlayer(Player player) {
    final index = _players.indexWhere((p) => p.id == player.id);
    if (index != -1) {
      _players[index] = player;
    } else {
      _players.add(player);
    }
    _playerController.add(_players);
  }

  /// Returns an unmodifiable list of all players.
  ///
  /// Prevents direct modification of the internal player list.
  ///
  /// Returns a copy of the current players.
  List<Player> getPlayers() => List.unmodifiable(_players);

  /// Retrieves a player by their unique identifier.
  ///
  /// [id] The unique identifier of the player to retrieve.
  ///
  /// Returns the player with the matching ID.
  ///
  /// Throws [StateError] if no player is found with the given ID.
  Player getPlayerById(int id) {
    return _players.firstWhere((player) => player.id == id);
  }

  /// Closes the stream controller and releases resources.
  ///
  /// Should be called when the repository is no longer needed to prevent memory
  /// leaks.
  void dispose() {
    _playerController.close();
  }
}
