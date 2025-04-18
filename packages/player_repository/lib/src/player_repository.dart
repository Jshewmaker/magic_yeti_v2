import 'dart:async';

import 'package:player_repository/models/player.dart';
import 'package:player_repository/models/game_snapshot.dart';
import 'package:rxdart/rxdart.dart';

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
  PlayerRepository();

  /// Initializes the repository and starts listening for game end events.
  void init() {
    _playerController.stream.listen(checkIfGameFinished);
  }

  /// Returns true if there is a previous game state that can be restored.
  bool get canRestoreGame => _previousGameSnapshot != null;

  /// Stores the previous game state snapshot for undo/restore functionality.
  GameSnapshot? _previousGameSnapshot;

  /// Internal stream controller for managing player list updates.
  final StreamController<List<Player>> _playerController =
      BehaviorSubject<List<Player>>();

  /// Internal list of players.
  final List<Player> _players = [];

  /// A stream of player lists that can be listened to for updates.
  ///
  /// Provides real-time updates whenever the player list changes.
  Stream<List<Player>> get players => _playerController.stream;

  /// Checks if the game has finished and updates the game state accordingly.
  ///
  /// This method is called whenever the player list changes and determines
  /// if the game has ended (only one active player remaining).
  /// If the game has finished, it takes a snapshot of the game state
  /// and declares the winner.
  void checkIfGameFinished(List<Player> players) {
    final numberOfPlayersEliminated =
        players.where((p) => p.state == PlayerModelState.eliminated).length;
    // Take a snapshot of the game state
    if (numberOfPlayersEliminated == (players.length - 2)) {
      _snapshotGameState();
    }

    // If only one player is left, declare them the winner
    if ((players.length - numberOfPlayersEliminated) == 1) {
      final winner =
          players.firstWhere((p) => p.state == PlayerModelState.active);
      final updatedWinner = winner.copyWith(
        placement: const Value(1),
        state: PlayerModelState.eliminated,
        timeOfDeath: Value(DateTime.now().millisecondsSinceEpoch),
      );
      _players[players.indexOf(winner)] = updatedWinner;
      _playerController.add(_players);
    }
  }

  /// Updates an existing player or adds a new player to the repository.
  ///
  /// If a player with the same ID exists, it will be replaced.
  /// If no matching player is found, the player will be added to the list.
  ///
  /// [player] The player to update or add.
  void updatePlayer(Player player) {
    // Check if this update will cause the game to end (only one active player left)
    final updatedPlayer = _checkPlayerDeath(player);

    final index = _players.indexWhere((p) => p.id == player.id);
    if (index == -1) {
      throw StateError(
        'Cannot update non-existent player with ID: ${player.id}',
      );
    }

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

  /// Takes a snapshot of the current game state for undo/restore functionality.
  void _snapshotGameState() {
    _previousGameSnapshot = GameSnapshot(
      players: _players.map((p) => p.copyWith()).toList(),
    );
  }

  /// Restores the previous game state snapshot, if available.
  /// Returns true if restoration was successful, false otherwise.
  bool restorePreviousGameState() {
    if (_previousGameSnapshot == null) return false;
    _players
      ..clear()
      ..addAll(
        _previousGameSnapshot!.players.map((p) => p.copyWith()).toList(),
      );

    _playerController.add(_players);
    _previousGameSnapshot = null;
    return true;
  }

  /// Checks if a player's life points have reached 0 or less and records their
  /// time of death.
  ///
  /// Returns the player with updated death time if applicable.
  Player _checkPlayerDeath(Player player) {
    final isLethalCommanderDamage =
        player.opponents?.any((p) => p.damages.any((d) => d.amount >= 21)) ??
            false;
    if (player.lifePoints <= 0 || isLethalCommanderDamage) {
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
