import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';

/// {@template firebase_database_repository}
/// Firebase database package
/// {@endtemplate}
class FirebaseDatabaseRepository {
  /// {@macro firebase_database_repository}
  const FirebaseDatabaseRepository({required FirebaseFirestore firebase})
      : _firebase = firebase;

  final FirebaseFirestore _firebase;

  /// Save game stats at end of game.
  Future<void> saveGameStats(GameModel game) async {
    await _firebase.collection('games').doc().set(game.toJson());
  }
}
