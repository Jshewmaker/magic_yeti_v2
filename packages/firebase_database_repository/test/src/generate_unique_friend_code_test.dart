import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:test/test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseDatabaseRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseDatabaseRepository(firebase: firestore);
  });

  group('generateUniqueFriendCode', () {
    test('is an 8-character uppercase alphanumeric code with no prefix',
        () async {
      final code = await repository.generateUniqueFriendCode();

      expect(code, hasLength(8));
      expect(code, matches(RegExp(r'^[A-Z0-9]{8}$')));
      expect(code, isNot(contains('-')));
      expect(code, isNot(startsWith('YETI')));
    });
  });
}
