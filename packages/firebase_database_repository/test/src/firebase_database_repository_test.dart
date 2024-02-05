// ignore_for_file: prefer_const_constructors
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  group('FirebaseDatabaseRepository', () {
    test('can be instantiated', () {});
  });
}
