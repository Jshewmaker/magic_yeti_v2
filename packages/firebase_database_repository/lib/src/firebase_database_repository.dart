import 'package:cloud_firestore/cloud_firestore.dart';

/// {@template firebase_database_repository}
/// Firebase database package
/// {@endtemplate}
class FirebaseDatabaseRepository {
  /// {@macro firebase_database_repository}
  const FirebaseDatabaseRepository({required FirebaseFirestore firebase})
      : _firebase = firebase;

  final FirebaseFirestore _firebase;

  /// Save game stats at end of game.
  Future<void> saveGameStats(List<Map<String, dynamic>> json) async {
    final date = DateTime.now();

    await _firebase
        .collection('game')
        .doc(date.toString())
        .set({'players': json});
  }
}
