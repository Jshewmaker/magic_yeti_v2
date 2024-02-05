import 'package:firebase_database/firebase_database.dart';

/// {@template firebase_database_repository}
/// Firebase database package
/// {@endtemplate}
class FirebaseDatabaseRepository {
  /// {@macro firebase_database_repository}
  const FirebaseDatabaseRepository({required FirebaseDatabase firebase})
      : _firebase = firebase;

  final FirebaseDatabase _firebase;

  void writeToDB() async {
    await _firebase.ref().set({'name': 'joshua'});
  }
}
