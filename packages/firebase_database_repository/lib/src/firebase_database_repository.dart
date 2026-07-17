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

/// {@template legacy_friend_request_exception}
/// Exception thrown when accepting a friend request fails because the
/// rules layer denies it with `permission-denied`. This happens for
/// requests created before the current friend/block rules shipped (e.g. a
/// legacy random-id doc that doesn't satisfy the deterministic-id
/// constraints the rules now require), so the accepting user is asked to
/// have the sender re-send the request instead of seeing a generic failure.
/// {@endtemplate}
class LegacyFriendRequestException implements Exception {
  /// {@macro legacy_friend_request_exception}
  const LegacyFriendRequestException({
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

  /// Update a user's profile.
  ///
  /// `usernameLower` is always derived from [UserProfileModel.username]
  /// here — the single choke point for every profile write — so it can
  /// never drift from whatever a caller happened to set (or forget to
  /// set) on the model. It powers the server-side `searchByUsername`
  /// prefix search. Operates on the JSON map directly (rather than
  /// `copyWith`, whose `??` pattern can't force a field back to null) so a
  /// null username always clears any stale `usernameLower` too.
  Future<void> updateUserProfile(
    String userId,
    UserProfileModel userProfile,
  ) async {
    try {
      final json = userProfile.toJson();
      final usernameLower = userProfile.username?.toLowerCase();
      if (usernameLower != null) {
        json['usernameLower'] = usernameLower;
      } else {
        json.remove('usernameLower');
      }
      await _firebase.collection('users').doc(userId).set(json);
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
      final doc = await _firebase.collection('users').doc(userId).get();
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

  /// Computes the deterministic `friendRequests` document id for a
  /// request from [senderId] to [receiverId].
  ///
  /// Requests are keyed by `{senderId}_{receiverId}` (rather than a random
  /// id) so that Firestore security rules can enforce the doc id shape on
  /// create, and so the sender/reverse-sender lookups below can read a
  /// single doc instead of running a query.
  static String friendRequestDocId(String senderId, String receiverId) =>
      '${senderId}_$receiverId';

  // Legacy-pending note: reverse-direction LEGACY (random-id) pendings won't
  // be found by the deterministic reverse read, so no auto-accept for them —
  // the sender simply creates a new deterministic request and the receiver
  // now has two pendings, one legacy (declinable) and one acceptable.
  // Acceptable drain path.
  /// Adds a friend request with guards against duplicates, self-requests,
  /// and existing friendships.
  ///
  /// [senderFriendCode] is denormalized onto the request doc so the
  /// receiver can tell the sender apart from anyone else sharing the same
  /// (non-unique) [senderName] — pass the sender's own profile friend
  /// code, not the receiver's.
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
    String? senderFriendCode,
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

    // Guard: reverse request exists — auto-accept. Checked BEFORE the
    // own-direction declined/pending short-circuit below: if Alice declined
    // Bob's request and Bob later sends Alice one, Alice tapping "Accept" on
    // Bob's search-card request re-invokes this method in the alice->bob
    // direction. That must auto-accept — not fall through to the stale
    // declined doc and return a fake silent "sent". A pending reverse doc
    // always gates the accept batch's rules-legal disjuncts (same code path
    // as the ordinary mutual-request auto-accept), so promoting this check
    // above the own-direction guard is safe regardless of the caller's own
    // prior history with the receiver.
    final reverseSnapshot = await _friendCollection
        .where('senderId', isEqualTo: receiverId)
        .where('receiverId', isEqualTo: senderId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (reverseSnapshot.docs.isNotEmpty) {
      final reverseModel = FriendRequestModel.fromJson(
        reverseSnapshot.docs.first.data()! as Map<String, dynamic>,
      );
      await acceptFriendRequest(reverseModel, senderId);
      return FriendRequestResult.autoAccepted;
    }

    // Guard: pending (or declined) request already sent. Point-gets on
    // possibly-missing friendRequests docs are rules-denied — a get() on a
    // NONEXISTENT doc evaluates `resource` as null, so the participant read
    // rule (which reads `resource.data.*`) errors out to DENIED — so guards
    // must be constraint-proven queries instead of deterministic doc reads.
    final ownSnapshot = await _friendCollection
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .limit(1)
        .get();
    if (ownSnapshot.docs.isNotEmpty) {
      final status =
          (ownSnapshot.docs.first.data()! as Map<String, dynamic>)['status'];
      // A declined request stays declined; the sender sees "sent" and the
      // receiver never sees it again (silent re-send suppression).
      if (status == 'declined') return FriendRequestResult.sent;
      return FriendRequestResult.alreadyPending;
    }

    // All clear — create the request at the deterministic doc id.
    try {
      final documentId = friendRequestDocId(senderId, receiverId);
      await _friendCollection.doc(documentId).set({
        'id': documentId,
        'senderId': senderId,
        'senderName': senderName,
        if (senderFriendCode != null) 'senderFriendCode': senderFriendCode,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return FriendRequestResult.sent;
    } on FirebaseException catch (e) {
      // A blocked sender is denied by rules; concealment is deliberate —
      // they see the same "sent" as everyone else (spec accepted tradeoff).
      if (e.code == 'permission-denied') return FriendRequestResult.sent;
      rethrow;
    }
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
      final receiverDoc = await _firebase.collection('users').doc(userId).get();

      final senderData = senderDoc.data();
      final receiverData = receiverDoc.data();

      // Build friend models from profile data with safe fallbacks
      final senderFriend = FriendModel(
        userId: request.senderId,
        username: senderData?['username'] as String? ?? request.senderName,
        profilePictureUrl: senderData?['imageUrl'] as String? ?? '',
        friendCode: senderData?['friendCode'] as String?,
      );

      final receiverFriend = FriendModel(
        userId: userId,
        username: receiverData?['username'] as String? ?? '',
        profilePictureUrl: receiverData?['imageUrl'] as String? ?? '',
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
    } on FirebaseException catch (e, stackTrace) {
      if (e.code == 'permission-denied') {
        throw LegacyFriendRequestException(
          message: 'Failed to accept friend request: $e',
          stackTrace: stackTrace,
        );
      }
      throw Exception('Failed to accept friend request: $e');
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  /// Removes a friend from both users' friend lists.
  ///
  /// Both edge deletes commit in one batch so a mid-operation failure
  /// can't leave a half-alive friendship (one edge deleted, the reverse
  /// intact) — the only realistic path to a friendship/pending-request
  /// state the rules reason about as impossible.
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      final batch = _firebase.batch()
        ..delete(
          _firebase
              .collection('friends')
              .doc(userId)
              .collection('friendList')
              .doc(friendId),
        )
        ..delete(
          _firebase
              .collection('friends')
              .doc(friendId)
              .collection('friendList')
              .doc(userId),
        );
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  /// Streams the user's friends, updating in real time.
  Stream<List<FriendModel>> watchFriends(String userId) {
    return _firebase
        .collection('friends')
        .doc(userId)
        .collection('friendList')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Streams the user's incoming pending friend requests, updating in real
  /// time.
  ///
  /// Deliberately the same query as `getFriendRequests` used — same equality
  /// filters, same `list` permission — so this needs no new composite index
  /// and no rules change. The only difference is a listener instead of a
  /// one-shot read.
  Stream<List<FriendRequestModel>> watchFriendRequests(String userId) {
    return _friendCollection
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FriendRequestModel.fromJson(
                  doc.data()! as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  /// Declines a friend request by marking its status as declined.
  ///
  /// The doc is retained (not deleted) so a future re-send from the same
  /// sender to the same receiver is silently suppressed — see
  /// [addFriendRequest].
  ///
  /// @param requestId The ID of the friend request to decline.
  /// @returns Future<void>
  /// @throws Exception if the request cannot be updated.
  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _friendCollection.doc(requestId).update({'status': 'declined'});
    } catch (e) {
      throw Exception('Failed to decline friend request: $e');
    }
  }

  /// Generates a unique 8-character friend code (e.g. "A3F9K2XQ").
  ///
  /// Plain random characters, no prefix — a prefix doesn't add any
  /// information (every code would carry the same one), and unlike a
  /// username-derived code, a fully random one never goes stale if the
  /// owner renames themselves.
  ///
  /// Checks for uniqueness against existing codes in the database.
  /// Retries up to 10 times if a collision is found.
  Future<String> generateUniqueFriendCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    const maxAttempts = 10;
    const codeLength = 8;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final friendCode = String.fromCharCodes(
        Iterable.generate(
          codeLength,
          (_) => chars.codeUnitAt(random.nextInt(chars.length)),
        ),
      );

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

  /// Searches for a user by their friend code via the block-aware
  /// `searchByFriendCode` callable.
  ///
  /// `found: false` is returned ONLY for a genuine server not-found result
  /// (which includes block-hiding — indistinguishable by design). An
  /// `invalid-argument` response is rethrown as an [ArgumentError]; any
  /// other callable failure (offline, internal, etc.) is thrown as a plain
  /// [Exception] so callers (e.g. SearchBloc) can surface their existing
  /// error state instead of silently reading as "not found".
  Future<FriendSearchResult> searchByFriendCode(String friendCode) async {
    try {
      final result = await _functions
          .httpsCallable('searchByFriendCode')
          .call<dynamic>({'code': friendCode});
      final data = Map<String, dynamic>.from(result.data as Map);

      if (data['found'] != true) return const FriendSearchResult(found: false);

      final userJson = Map<String, dynamic>.from(data['user'] as Map);
      final relationship = _relationshipFromString(
        data['relationship'] as String?,
      );

      return FriendSearchResult(
        found: true,
        user: UserProfileModel.fromJson(userJson),
        relationship: relationship,
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'invalid-argument') {
        throw ArgumentError(e.message ?? 'Invalid friend code');
      }
      throw Exception('Friend code search unavailable');
    }
  }

  /// Searches for users by username prefix (case-insensitive) via the
  /// block-aware `searchByUsername` callable. Returns an empty list when
  /// nothing matches; throws [ArgumentError] for an `invalid-argument`
  /// response (e.g. a query shorter than the server's minimum length), and
  /// a plain [Exception] for any other callable failure.
  Future<List<UserSearchMatch>> searchByUsername(String query) async {
    try {
      final result = await _functions
          .httpsCallable('searchByUsername')
          .call<dynamic>({'query': query});
      final data = Map<String, dynamic>.from(result.data as Map);
      final matches = List<dynamic>.from(data['matches'] as List);

      return matches.map((match) {
        final matchMap = Map<String, dynamic>.from(match as Map);
        final userJson = Map<String, dynamic>.from(matchMap['user'] as Map);
        return UserSearchMatch(
          user: UserProfileModel.fromJson(userJson),
          relationship: _relationshipFromString(
            matchMap['relationship'] as String?,
          ),
        );
      }).toList();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'invalid-argument') {
        throw ArgumentError(e.message ?? 'Invalid search query');
      }
      throw Exception('Username search unavailable');
    }
  }

  /// Maps the callable's relationship string onto [RelationshipStatus].
  static RelationshipStatus _relationshipFromString(String? value) {
    switch (value) {
      case 'friends':
        return RelationshipStatus.friends;
      case 'pendingSent':
        return RelationshipStatus.pendingSent;
      case 'pendingReceived':
        return RelationshipStatus.pendingReceived;
      case 'self':
        return RelationshipStatus.self;
      case 'none':
      default:
        return RelationshipStatus.none;
    }
  }

  /// Blocks [target]: writes the owner-managed block doc (denormalized
  /// username/imageUrl + server timestamp), removes both friendship edges,
  /// and deletes any pending friend-request docs between the two users.
  ///
  /// Under the Task 3 rules, `friendRequests` deletes are pending-only —
  /// deleting a nonexistent doc (null `resource.data`) or a declined doc
  /// is denied. Declined docs don't need deleting: they're already invisible
  /// to [watchFriendRequests] and permanently suppress re-sends. Rather than
  /// point-getting the deterministic docs (which is rules-denied when the
  /// doc doesn't exist — see [addFriendRequest]), this queries both pending
  /// directions by sender/receiver id, which matches deterministic-id docs
  /// just as well as legacy random-id ones: query results are pending by
  /// construction, so no existence/status check is needed for them.
  Future<void> blockUser({
    required String currentUserId,
    required BlockedUserModel target,
  }) async {
    final batch = _firebase.batch()
      ..set(
        _firebase
            .collection('users')
            .doc(currentUserId)
            .collection('blocks')
            .doc(target.userId),
        {
          'userId': target.userId,
          'username': target.username,
          'imageUrl': target.imageUrl,
          if (target.friendCode != null) 'friendCode': target.friendCode,
          'blockedAt': FieldValue.serverTimestamp(),
        },
      )
      ..delete(
        _firebase
            .collection('friends')
            .doc(currentUserId)
            .collection('friendList')
            .doc(target.userId),
      )
      ..delete(
        _firebase
            .collection('friends')
            .doc(target.userId)
            .collection('friendList')
            .doc(currentUserId),
      );

    // Pending requests in both directions (covers deterministic AND legacy
    // random-id docs — the query matches on sender/receiver id, not doc id).
    final legacySent = await _friendCollection
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: target.userId)
        .where('status', isEqualTo: 'pending')
        .get();
    for (final doc in legacySent.docs) {
      batch.delete(doc.reference);
    }

    final legacyReceived = await _friendCollection
        .where('senderId', isEqualTo: target.userId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get();
    for (final doc in legacyReceived.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Unblocks a user by deleting the block doc only. Friendship edges and
  /// requests were already removed at block time and are not restored.
  Future<void> unblockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _firebase
        .collection('users')
        .doc(currentUserId)
        .collection('blocks')
        .doc(targetUserId)
        .delete();
  }

  /// Streams the current user's blocked users, newest-first.
  Stream<List<BlockedUserModel>> getBlockedUsers(String userId) {
    return _firebase
        .collection('users')
        .doc(userId)
        .collection('blocks')
        .orderBy('blockedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BlockedUserModel.fromJson(doc.data()))
              .toList(),
        );
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
      if (e.code == 'failed-precondition') {
        return const PinNotSet();
      }
      return const PinCheckUnavailable();
    } catch (_) {
      return const PinCheckUnavailable();
    }
  }

  /// Ensures a user profile document exists with a friend code.
  ///
  /// If the profile doesn't exist, creates it from the provided
  /// [UserProfileModel]. If it exists but is missing a friend code,
  /// generates and adds one. Returns the current friend code.
  Future<String?> ensureUserProfile(UserProfileModel profile) async {
    try {
      final doc = await _firebase.collection('users').doc(profile.id).get();

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
  ///
  /// Note: if a pre-update client changes the legacy PIN on a device that
  /// hasn't picked up this migration, and that change lands after this
  /// migration already ran, the change is silently discarded — the
  /// credentials doc wins and the next `migrateLegacyPin` call simply
  /// deletes the new legacy hash again. This is accepted behavior; there
  /// is no cross-device coordination for legacy-field writes.
  Future<void> migrateLegacyPin(String userId) async {
    try {
      final profileRef = _firebase.collection('users').doc(userId);
      final profile = await profileRef.get();
      if (!profile.exists) return;
      final legacyHash = profile.data()?['pin'] as String?;
      if (legacyHash == null || legacyHash.isEmpty) {
        // Self-heal: an old-version client's full-doc profile write can
        // wipe the hasPin flag after migration already ran. If the
        // credentials doc exists but the flag is missing, repair it so
        // the completeness gate does not bounce a PIN-holding user back
        // into onboarding.
        if (profile.data()?['hasPin'] != true) {
          final credentials = await _credentialsDoc(userId).get();
          if (credentials.exists) {
            unawaited(
              profileRef
                  .set({'hasPin': true}, SetOptions(merge: true))
                  .catchError((Object _) {}),
            );
          }
        }
        return;
      }

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
      // Fire-and-forget: offline, commit() never completes (Firestore
      // queues it locally and syncs later); awaiting it here would wedge
      // AppBloc's sequential auth-event queue. Local reads already
      // reflect the pending write, and the callable's legacy fallback
      // covers the gap until it syncs.
      unawaited(
        batch.commit().catchError((Object _) {}),
      );
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
