import 'dart:async';

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

/// {@template delete_match_exception}
/// Exception thrown when deleting a match fails.
/// {@endtemplate}
class DeleteMatchException implements Exception {
  /// {@macro delete_match_exception}
  const DeleteMatchException({
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
/// Exception thrown when a game is not found.
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

/// {@template get_game_exception}
/// Exception thrown when getting a game fails.
/// {@endtemplate}
class GetGameException implements Exception {
  /// {@macro get_game_exception}
  const GetGameException({
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
  ///
  /// Takes a [GameModel] and returns the document ID of the saved game.
  Future<String> saveGameStats(GameModel game) async {
    try {
      final newDoc = _firebase.collection('games').doc();
      await _firebase.collection('games').doc(newDoc.id).set(
            game.copyWith(id: newDoc.id).toJson(),
          );
      return newDoc.id;
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
        (snapshot) {
          return snapshot.docs.map((doc) {
            final game = GameModel.fromJson(doc.data());
            return game;
          }).toList();
        },
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
    } on FirebaseException catch (error, stackTrace) {
      throw GetGameException(
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

  /// Delete a match from the player's history
  Future<void> deleteGame(String gameId, String playerId) async {
    try {
      await _firebase
          .collection('users')
          .doc(playerId)
          .collection('matches')
          .doc(gameId)
          .delete();
    } on Exception catch (error, stackTrace) {
      throw DeleteMatchException(
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

  /// Adds a friend request to the Firestore database.
  ///
  /// @param senderId The ID of the user sending the request.
  /// @param receiverId The ID of the user receiving the request.
  /// @returns Future<void>
  /// @throws Exception if the request cannot be added.
  Future<void> addFriendRequest(
      String senderId, String senderName, String receiverId) async {
    try {
      await _firebase.collection('FriendRequests').add({
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add friend request: $e');
    }
  }

  /// Accepts a friend request by updating its status in the Firestore database.
  ///
  /// @param requestId The ID of the friend request to accept.
  /// @returns Future<void>
  /// @throws Exception if the request cannot be updated.
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _firebase.collection('FriendRequests').doc(requestId).update({
        'status': 'accepted',
      });
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  /// Removes a friend from the Firestore database.
  ///
  /// @param userId The ID of the user whose friend is being removed.
  /// @param friendId The ID of the friend to remove.
  /// @returns Future<void>
  /// @throws Exception if the friend cannot be removed.
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      final QuerySnapshot snapshot = await _firebase
          .collection('Friends')
          .where('userId', isEqualTo: userId)
          .where('friendId', isEqualTo: friendId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  /// Retrieves the list of friends for a given user.
  ///
  /// @param userId The ID of the user whose friends are being retrieved.
  /// @returns Future<List<String>> A list of friend IDs.
  /// @throws Exception if the friends cannot be retrieved.
  Future<List<FriendModel>> getFriends(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firebase
          .collection('Friends')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) =>
              FriendModel.fromJson(doc.data()! as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to retrieve friends: $e');
    }
  }

  /// Searches for users by username or email.
  ///
  /// @param searchTerm The term to search for in usernames or emails.
  /// @returns Future<List<Map<String, dynamic>>> A list of user data maps.
  /// @throws Exception if the search fails.
  Future<List<UserProfileModel>> searchUsers(String searchTerm) async {
    try {
      final QuerySnapshot usernameSnapshot = await _firebase
          .collection('Users')
          .where('username', isEqualTo: searchTerm)
          .get();

      final QuerySnapshot emailSnapshot = await _firebase
          .collection('Users')
          .where('email', isEqualTo: searchTerm)
          .get();

      final users = <UserProfileModel>[];

      for (final doc in usernameSnapshot.docs) {
        users.add(doc.data()! as UserProfileModel);
      }

      for (final doc in emailSnapshot.docs) {
        users.add(doc.data()! as UserProfileModel);
      }

      return users;
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Retrieves all incoming friend requests for a given user.
  ///
  /// @param userId The ID of the user whose incoming friend requests are being retrieved.
  /// @returns Future<List<FriendRequestModel>> A list of friend request data.
  /// @throws Exception if the friend requests cannot be retrieved.
  Future<List<FriendRequestModel>> getFriendRequests(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firebase
          .collection('FriendRequests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()! as FriendRequestModel)
          .toList();
    } catch (e) {
      throw Exception('Failed to retrieve friend requests: $e');
    }
  }

  /// Declines a friend request by removing it from the Firestore database.
  ///
  /// @param requestId The ID of the friend request to decline.
  /// @returns Future<void>
  /// @throws Exception if the request cannot be removed.
  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _firebase.collection('FriendRequests').doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to decline friend request: $e');
    }
  }
}
