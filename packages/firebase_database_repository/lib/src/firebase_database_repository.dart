import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_database_repository/models/models.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  FirebaseDatabaseRepository({
    required FirebaseFirestore firebase,
    FirebaseFunctions? functions,
  })  : _firebase = firebase,
        _functionsOverride = functions;

  final FirebaseFirestore _firebase;
  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  CollectionReference get _friendCollection =>
      _firebase.collection('friendRequests');

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

  /// Get a user's profile as a one-shot Future.
  /// Returns null if the document does not exist.
  Future<UserProfileModel?> getUserProfileOnce(String userId) async {
    try {
      final doc =
          await _firebase.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfileModel.fromJson(doc.data()!);
    } on Exception catch (error, stackTrace) {
      throw GetUserProfileException(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Upload a profile picture to Firebase Storage.
  /// Accepts raw image bytes for cross-platform compatibility.
  /// Returns the download URL.
  Future<String> uploadProfilePicture(
    String userId,
    Uint8List imageBytes,
  ) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');
      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return storageRef.getDownloadURL();
    } on Exception catch (error, stackTrace) {
      throw UpdateUserProfileException(
        message: 'Failed to upload profile picture: $error',
        stackTrace: stackTrace,
      );
    }
  }

  /// Adds a friend request with guards against duplicates, self-requests,
  /// and existing friendships.
  ///
  /// Returns [FriendRequestResult] indicating what happened:
  /// - [FriendRequestResult.sent] — request created
  /// - [FriendRequestResult.autoAccepted] — mutual request, now friends
  /// - [FriendRequestResult.alreadyFriends] — already friends
  /// - [FriendRequestResult.alreadyPending] — request already exists
  /// - [FriendRequestResult.self] — cannot add yourself
  Future<FriendRequestResult> addFriendRequest(
    String senderId,
    String senderName,
    String receiverId,
  ) async {
    // Guard: self-request
    if (senderId == receiverId) return FriendRequestResult.self;

    // Guard: already friends
    final friendDoc = await _firebase
        .collection('friends')
        .doc(senderId)
        .collection('friendList')
        .doc(receiverId)
        .get();
    if (friendDoc.exists) return FriendRequestResult.alreadyFriends;

    // Guard: pending request already sent
    final existingSent = await _friendCollection
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existingSent.docs.isNotEmpty) {
      return FriendRequestResult.alreadyPending;
    }

    // Guard: reverse request exists — auto-accept
    final reverseRequest = await _friendCollection
        .where('senderId', isEqualTo: receiverId)
        .where('receiverId', isEqualTo: senderId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (reverseRequest.docs.isNotEmpty) {
      final reverseDoc = reverseRequest.docs.first;
      final reverseModel = FriendRequestModel.fromJson(
        reverseDoc.data()! as Map<String, dynamic>,
      );
      await acceptFriendRequest(reverseModel, senderId);
      return FriendRequestResult.autoAccepted;
    }

    // All clear — create the request
    final newRequestRef = _friendCollection.doc();
    final documentId = newRequestRef.id;
    await newRequestRef.set({
      'id': documentId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return FriendRequestResult.sent;
  }

  /// Accepts a friend request by updating its status in the Firestore database.
  ///
  /// @param requestId The ID of the friend request to accept.
  /// @returns Future<void>
  /// @throws Exception if the request cannot be updated.
  Future<void> acceptFriendRequest(
    FriendRequestModel request,
    String userId,
  ) async {
    try {
      final senderDoc =
          await _firebase.collection('users').doc(request.senderId).get();
      final receiverDoc =
          await _firebase.collection('users').doc(userId).get();

      final senderData = senderDoc.data();
      final receiverData = receiverDoc.data();

      // Build friend models from profile data with safe fallbacks
      final senderFriend = FriendModel(
        userId: request.senderId,
        username: senderData?['username'] as String? ??
            request.senderName,
        profilePictureUrl:
            senderData?['imageUrl'] as String? ?? '',
        friendCode: senderData?['friendCode'] as String?,
      );

      final receiverFriend = FriendModel(
        userId: userId,
        username: receiverData?['username'] as String? ?? '',
        profilePictureUrl:
            receiverData?['imageUrl'] as String? ?? '',
        friendCode: receiverData?['friendCode'] as String?,
      );

      // Write both sides of the friendship in a batch
      final batch = _firebase.batch();

      batch.set(
        _firebase
            .collection('friends')
            .doc(userId)
            .collection('friendList')
            .doc(request.senderId),
        senderFriend.toJson(),
      );

      batch.set(
        _firebase
            .collection('friends')
            .doc(request.senderId)
            .collection('friendList')
            .doc(userId),
        receiverFriend.toJson(),
      );

      batch.delete(_friendCollection.doc(request.id));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  /// Removes a friend from both users' friend lists.
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      await _firebase
          .collection('friends')
          .doc(userId)
          .collection('friendList')
          .doc(friendId)
          .delete();

      await _firebase
          .collection('friends')
          .doc(friendId)
          .collection('friendList')
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  /// Retrieves the list of friends for a given user.
  Future<List<FriendModel>> getFriends(String userId) async {
    try {
      final snapshot = await _firebase
          .collection('friends')
          .doc(userId)
          .collection('friendList')
          .get();

      return snapshot.docs
          .map((doc) => FriendModel.fromJson(doc.data()))
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
          .collection('users')
          .where('username', isEqualTo: searchTerm)
          .get();

      final QuerySnapshot emailSnapshot = await _firebase
          .collection('users')
          .where('email', isEqualTo: searchTerm)
          .get();

      final users = <UserProfileModel>[];

      for (final doc in usernameSnapshot.docs) {
        users.add(
            UserProfileModel.fromJson(doc.data()! as Map<String, dynamic>));
      }

      for (final doc in emailSnapshot.docs) {
        users.add(
            UserProfileModel.fromJson(doc.data()! as Map<String, dynamic>));
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
      final snapshot = await _friendCollection
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) =>
              FriendRequestModel.fromJson(doc.data()! as Map<String, dynamic>))
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
      await _friendCollection.doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to decline friend request: $e');
    }
  }

  /// Generates a unique friend code in the format "YETI-XXXX".
  ///
  /// Checks for uniqueness against existing codes in the database.
  /// Retries up to 10 times if a collision is found.
  Future<String> generateUniqueFriendCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    const maxAttempts = 10;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code = String.fromCharCodes(
        Iterable.generate(
          4,
          (_) => chars.codeUnitAt(random.nextInt(chars.length)),
        ),
      );
      final friendCode = 'YETI-$code';

      final existing = await _firebase
          .collection('users')
          .where('friendCode', isEqualTo: friendCode)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        return friendCode;
      }
    }

    throw Exception('Failed to generate unique friend code after $maxAttempts '
        'attempts');
  }

  /// Searches for a user by their friend code.
  ///
  /// Returns the matching [UserProfileModel] or `null` if not found.
  Future<UserProfileModel?> searchByFriendCode(String friendCode) async {
    try {
      final snapshot = await _firebase
          .collection('users')
          .where('friendCode', isEqualTo: friendCode.toUpperCase().trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return UserProfileModel.fromJson(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to search by friend code: $e');
    }
  }

  /// Checks the relationship status between two users.
  ///
  /// Returns [RelationshipStatus] indicating the current state:
  /// self, friends, pendingSent, pendingReceived, or none.
  Future<RelationshipStatus> checkRelationshipStatus(
    String currentUserId,
    String otherUserId,
  ) async {
    if (currentUserId == otherUserId) return RelationshipStatus.self;

    // Check if already friends
    final friendDoc = await _firebase
        .collection('friends')
        .doc(currentUserId)
        .collection('friendList')
        .doc(otherUserId)
        .get();
    if (friendDoc.exists) return RelationshipStatus.friends;

    // Check if current user sent a pending request
    final sentRequest = await _friendCollection
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: otherUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (sentRequest.docs.isNotEmpty) return RelationshipStatus.pendingSent;

    // Check if other user sent a pending request
    final receivedRequest = await _friendCollection
        .where('senderId', isEqualTo: otherUserId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (receivedRequest.docs.isNotEmpty) {
      return RelationshipStatus.pendingReceived;
    }

    return RelationshipStatus.none;
  }

  /// Hashes a 4-digit PIN using SHA-256.
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Generates a random 16-byte hex salt for PIN hashing.
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes a PIN with a salt: sha256(salt + pin).
  static String saltedPinHash(String pin, String salt) {
    final bytes = utf8.encode(salt + pin);
    return sha256.convert(bytes).toString();
  }

  /// Gets a reference to a user's private credentials document.
  DocumentReference<Map<String, dynamic>> _credentialsDoc(String userId) =>
      _firebase.doc('users/$userId/private/credentials');

  /// Validates a friend's PIN via the `validatePin` Cloud Function.
  ///
  /// The hash never reaches this client; the server enforces the
  /// 5-failures / 15-minute lockout and the friends-only precondition.
  Future<PinValidationResult> validatePin({
    required String targetUserId,
    required String pin,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('validatePin')
          .call<dynamic>({'targetUserId': targetUserId, 'pin': pin});
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['valid'] == true) return const PinValid();
      return PinInvalid(
        attemptsRemaining: (data['attemptsRemaining'] as num?)?.toInt() ?? 0,
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        final details = e.details;
        final millis = details is Map
            ? (details['lockedUntilMillis'] as num?)?.toInt()
            : null;
        return PinLockedOut(
          lockedUntil: millis != null
              ? DateTime.fromMillisecondsSinceEpoch(millis)
              : DateTime.now().add(const Duration(minutes: 15)),
        );
      }
      return const PinCheckUnavailable();
    } catch (_) {
      return const PinCheckUnavailable();
    }
  }

  /// Syncs a completed game to all authenticated players' match histories.
  ///
  /// Saves the [GameModel] to `users/{firebaseId}/matches/{gameId}` for
  /// each unique Firebase ID in [playerFirebaseIds].
  Future<void> syncGameToPlayers(
    GameModel game,
    List<String> playerFirebaseIds,
  ) async {
    final uniqueIds = playerFirebaseIds.toSet();
    final futures = uniqueIds.map(
      (id) => addMatchToPlayerHistory(game, id),
    );
    await Future.wait(futures);
  }

  /// Ensures a user profile document exists with a friend code.
  ///
  /// If the profile doesn't exist, creates it from the provided
  /// [UserProfileModel]. If it exists but is missing a friend code,
  /// generates and adds one. Returns the current friend code.
  Future<String?> ensureUserProfile(UserProfileModel profile) async {
    try {
      final doc =
          await _firebase.collection('users').doc(profile.id).get();

      if (!doc.exists) {
        // No profile at all — create a full one with friend code
        final friendCode = await generateUniqueFriendCode();
        await _firebase.collection('users').doc(profile.id).set(
              profile.copyWith(friendCode: friendCode).toJson(),
            );
        return friendCode;
      }

      final data = doc.data()!;
      final existingCode = data['friendCode'] as String?;
      if (existingCode != null) return existingCode;

      // Profile exists but no friend code — add one
      final friendCode = await generateUniqueFriendCode();
      await _firebase.collection('users').doc(profile.id).set(
        {'friendCode': friendCode},
        SetOptions(merge: true),
      );
      return friendCode;
    } catch (e) {
      return null;
    }
  }

  /// Sets the user's PIN: salted hash into the private credentials doc,
  /// `hasPin` flag onto the profile, legacy `pin` field removed.
  Future<void> setPin(String userId, String pin) async {
    try {
      final salt = generateSalt();
      final batch = _firebase.batch()
        ..set(_credentialsDoc(userId), {
          'pinHash': saltedPinHash(pin, salt),
          'salt': salt,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        ..set(
          _firebase.collection('users').doc(userId),
          {'hasPin': true, 'pin': FieldValue.delete()},
          SetOptions(merge: true),
        );
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set PIN: $e');
    }
  }

  /// Moves a legacy profile-doc PIN hash into the private credentials
  /// doc. Safe to call on every login; no-ops when nothing to migrate.
  Future<void> migrateLegacyPin(String userId) async {
    try {
      final profileRef = _firebase.collection('users').doc(userId);
      final profile = await profileRef.get();
      if (!profile.exists) return;
      final legacyHash = profile.data()?['pin'] as String?;
      if (legacyHash == null || legacyHash.isEmpty) return;

      final credentials = await _credentialsDoc(userId).get();
      final batch = _firebase.batch();
      if (!credentials.exists) {
        batch.set(_credentialsDoc(userId), {
          'pinHash': legacyHash,
          'salt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      batch.set(
        profileRef,
        {'hasPin': true, 'pin': FieldValue.delete()},
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (_) {
      // Migration is best-effort on login; the callable's legacy
      // fallback keeps validation working until it succeeds.
    }
  }

  /// Checks whether a user has set their PIN (new flag or legacy field).
  Future<bool> hasPin(String userId) async {
    try {
      final doc = await _firebase.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final legacy = data['pin'] as String?;
      return data['hasPin'] == true || (legacy != null && legacy.isNotEmpty);
    } catch (e) {
      return false;
    }
  }
}
