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
    if (index == -1) {
      throw StateError(
          'Cannot update non-existent player with ID: ${player.id}');
    }
    final updatedPlayer = _checkPlayerDeath(player);
    _players[index] = updatedPlayer;
    _playerController.add(_players);
  }

  /// Adds a new player to the repository.
  ///
  /// If a player with the same ID already exists, a [StateError] is thrown.
  ///
  /// [player] The player to add.
  void createPlayer(Player player) {
    final exists = _players.any((p) => p.id == player.id);
    if (exists) {
      throw StateError('Player with ID ${player.id} already exists');
    }
    _players.add(player);
    _playerController.add(_players);
  }

  /// Checks if a player's life points have reached 0 or less and records their
  /// time of death.
  ///
  /// Returns the player with updated death time if applicable.
  Player _checkPlayerDeath(Player player) {
    if (player.lifePoints <= 0) {
      // Only set death time and placement if they're still active
      if (player.isActive) {
        // Count how many players are already eliminated to determine placement
        final totalPlayers = _players.length;
        final eliminatedPlayers = _players.where((p) => p.isEliminated).length;
        // Placement is total players minus number of already eliminated players
        // For example: in a 4 player game, first death = 4, second = 3, etc.
        final placement = totalPlayers - eliminatedPlayers;

        return player.copyWith(
          state: PlayerModelState.eliminated,
          timeOfDeath: Value(DateTime.now().millisecondsSinceEpoch),
          placement: Value(placement),
        );
      }
      return player;
    }
    if (player.lifePoints > 0 && player.isEliminated) {
      return player.copyWith(
        state: PlayerModelState.active,
        timeOfDeath: const Value(null),
        placement: const Value(null),
      );
    }
    return player;
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
  Player getPlayerById(String id) {
    return _players.firstWhere((player) => player.id == id);
  }

  /// Removes all players from the repository and notifies listeners.
  ///
  /// This will clear the internal player list and emit an empty list
  /// through the stream.
  void clearPlayers() {
    _players.clear();
    _playerController.add(_players);
  }

  /// Closes the stream controller and releases resources.
  ///
  /// Should be called when the repository is no longer needed to prevent memory
  /// leaks.
  void dispose() {
    _playerController.close();
  }
}
