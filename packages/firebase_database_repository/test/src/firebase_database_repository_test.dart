// ignore_for_file: prefer_const_constructors
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:test/test.dart';

void main() {
  group('FirebaseDatabaseRepository', () {
    test('can be instantiated', () {
      expect(FirebaseDatabaseRepository(), isNotNull);
    });
  });
}
