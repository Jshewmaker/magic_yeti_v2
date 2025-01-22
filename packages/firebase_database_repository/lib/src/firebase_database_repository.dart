import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:player_repository/player_repository.dart';
import '../models/game_model.dart';
import 'dart:math';

/// {@template save_game_stats_exception}
/// Exception thrown when saving game stats fails.
/// {@endtemplate}
class SaveGameStatsException implements Exception {
  /// {@macro save_game_stats_exception}
  const SaveGameStatsException({
    required this.message,
    required this.stackTrace,
  });

  /// A description of the error.
  final String message;

  /// The stack trace for the exception.
  final Object stackTrace;
}

/// {@template get_games_exception}
/// Exception thrown when getting games fails.
/// {@endtemplate}
class GetGamesException implements Exception {
  /// {@macro get_games_exception}
  const GetGamesException({
    required this.message,
    required this.stackTrace,
  });

  /// A description of the error.
  final String message;

  /// The stack trace for the exception.
  final Object stackTrace;
}

/// {@template add_match_to_player_history_exception}
/// Exception thrown when adding a match to the player's history fails.
/// {@endtemplate}
class AddMatchToPlayerHistoryException implements Exception {
  /// {@macro add_match_to_player_history_exception}
  const AddMatchToPlayerHistoryException({
    required this.message,
    required this.stackTrace,
  });

  /// A description of the error.
  final String message;

  /// The stack trace for the exception.
  final Object stackTrace;
}

/// {@template firebase_database_repository}
/// Firebase database package
/// {@endtemplate}
class FirebaseDatabaseRepository {
  /// {@macro firebase_database_repository}
  const FirebaseDatabaseRepository({required FirebaseFirestore firebase})
      : _firebase = firebase;

  final FirebaseFirestore _firebase;

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
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      final gameId = _getRandomString(4);
      final exists = await _firebase
          .collection('games')
          .where('roomId', isEqualTo: gameId)
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty);

      if (!exists) {
        return gameId;
      }
      attempts++;
    }
    throw Exception('Failed to generate unique game ID');
  }

  /// Save game stats at end of game.
  Future<void> saveGameStats(GameModel game) async {
    try {
      final shortId = await generateShortGameId();
      final gameWithShortId = game.copyWith(roomId: shortId);
      await _firebase.collection('games').doc().set(gameWithShortId.toJson());
    } on Exception catch (error, stackTrace) {
      throw SaveGameStatsException(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Get a stream of games that updates in real time
  Stream<List<GameModel>> getGames(String userId) {
    try {
      return _firebase
          .collection('users')
          .doc(userId)
          .collection('matches')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => GameModel.fromJson(doc.data()))
                .toList(),
          );
    } on Exception catch (e) {
      throw GetGamesException(
        message: e.toString(),
        stackTrace: StackTrace.current,
      );
    }
  }

  /// Update player data in Firebase for the current game
  Future<void> updatePlayerData(Player player) async {
    final gameSnapshot = await _firebase
        .collection('games')
        .orderBy('endTime', descending: true)
        .limit(1)
        .get();

    if (gameSnapshot.docs.isEmpty) return;

    final gameDoc = gameSnapshot.docs.first;
    final game = GameModel.fromJson(gameDoc.data());

    final updatedPlayers = game.players.map((p) {
      if (p.id == player.id) {
        return player;
      }
      return p;
    }).toList();

    final updatedGame = game.copyWith(players: updatedPlayers);
    await gameDoc.reference.update(updatedGame.toJson());
  }

  /// Add a match to the player's history
  Future<void> addMatchToPlayerHistory(GameModel game, String playerId) async {
    try {
      await _firebase
          .collection('users')
          .doc(playerId)
          .collection('matches')
          .doc()
          .set(game.toJson());
    } on Exception catch (error, stackTrace) {
      throw AddMatchToPlayerHistoryException(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }
}
