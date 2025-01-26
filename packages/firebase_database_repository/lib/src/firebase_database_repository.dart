import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database_repository/models/models.dart';

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

/// {@template get_game_exception}
/// Exception thrown when getting a game fails.
/// {@endtemplate}
class GameNotFoundException implements Exception {
  /// {@macro get_game_exception}
  const GameNotFoundException({
    required this.message,
    required this.stackTrace,
  });

  /// A description of the error.
  final String message;

  /// The stack trace for the exception.
  final Object stackTrace;
}

/// {@template update_user_profile_exception}
/// Exception thrown when updating a user profile fails.
/// {@endtemplate}
class UpdateUserProfileException implements Exception {
  /// {@macro update_user_profile_exception}
  const UpdateUserProfileException({
    required this.message,
    required this.stackTrace,
  });

  /// A description of the error.
  final String message;

  /// The stack trace for the exception.
  final Object stackTrace;
}

/// {@template get_user_profile_exception}
/// Exception thrown when getting a user profile fails.
/// {@endtemplate}
class GetUserProfileException implements Exception {
  /// {@macro get_user_profile_exception}
  const GetUserProfileException({
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

  /// Check if a game ID already exists
  Future<bool> checkIfGameIdExists(String gameId) async {
    try {
      return await _firebase
          .collection('games')
          .where('roomId', isEqualTo: gameId)
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty);
    } on Exception catch (error, stackTrace) {
      throw GetGamesException(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Save game stats at end of game.
  Future<void> saveGameStats(GameModel game) async {
    try {
      final newDoc = _firebase.collection('games').doc();
      await _firebase.collection('games').doc(newDoc.id).set(
            game.copyWith(id: newDoc.id).toJson(),
          );
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

  /// Get a specific game by its roomID
  Future<GameModel> getGame(String gameId) async {
    try {
      final gameSnapshot = await _firebase
          .collection('games')
          .where('roomId', isEqualTo: gameId)
          .limit(1)
          .get();
      if (gameSnapshot.docs.isNotEmpty) {
        return GameModel.fromJson(gameSnapshot.docs.first.data());
      } else {
        throw GameNotFoundException(
          message: 'Game with ID $gameId not found',
          stackTrace: StackTrace.current,
        );
      }
    } on Exception catch (error, stackTrace) {
      throw GameNotFoundException(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Add a match to the player's history
  Future<void> addMatchToPlayerHistory(GameModel game, String playerId) async {
    try {
      await _firebase
          .collection('users')
          .doc(playerId)
          .collection('matches')
          .doc(game.id)
          .set(game.toJson());
    } on Exception catch (error, stackTrace) {
      throw AddMatchToPlayerHistoryException(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Update a match in the player's history
  Future<void> updateGameStats({
    required GameModel game,
    required String playerId,
  }) async {
    try {
      await _firebase
          .collection('users')
          .doc(playerId)
          .collection('matches')
          .doc(game.id)
          .set(game.toJson());
    } on Exception catch (error, stackTrace) {
      throw SaveGameStatsException(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Update a user's profile
  Future<void> updateUserProfile(
    String userId,
    UserProfileModel userProfile,
  ) async {
    try {
      await _firebase.collection('users').doc(userId).set(userProfile.toJson());
    } on Exception catch (error, stackTrace) {
      throw UpdateUserProfileException(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Get a user's profile
  Stream<UserProfileModel> getUserProfile(String userId) {
    try {
      return _firebase
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) => UserProfileModel.fromJson(doc.data()!));
    } on Exception catch (error, stackTrace) {
      throw GetUserProfileException(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }
}
