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

  group('watchFriendRequests', () {
    test('emits pending requests addressed to the user', () async {
      await repository.addFriendRequest('bob', 'Bob', null, 'alice');

      final requests = await repository.watchFriendRequests('alice').first;

      expect(requests.map((r) => r.id), ['bob_alice']);
    });

    test('does not emit requests addressed to somebody else', () async {
      await repository.addFriendRequest('bob', 'Bob', null, 'carol');

      final requests = await repository.watchFriendRequests('alice').first;

      expect(requests, isEmpty);
    });

    test('does not emit declined requests', () async {
      await repository.addFriendRequest('bob', 'Bob', null, 'alice');
      await repository.declineFriendRequest('bob_alice');

      final requests = await repository.watchFriendRequests('alice').first;

      expect(requests, isEmpty);
    });

    test('re-emits without the request once it is accepted', () async {
      await repository.addFriendRequest('bob', 'Bob', null, 'alice');
      final request =
          (await repository.watchFriendRequests('alice').first).single;

      // Map to ids so the matcher does not depend on model equality.
      final emissions = repository
          .watchFriendRequests('alice')
          .map((rs) => rs.map((r) => r.id).toList());

      final expectation = expectLater(
        emissions,
        emitsInOrder([
          ['bob_alice'],
          isEmpty,
        ]),
      );

      await repository.acceptFriendRequest(request, 'alice');
      await expectation;
    });
  });

  group('watchFriends', () {
    test('emits an empty list when the user has no friends', () async {
      expect(await repository.watchFriends('alice').first, isEmpty);
    });

    test('emits the friend once a request is accepted', () async {
      await repository.addFriendRequest('bob', 'Bob', null, 'alice');
      final request =
          (await repository.watchFriendRequests('alice').first).single;

      final emissions = repository
          .watchFriends('alice')
          .map((fs) => fs.map((f) => f.userId).toList());

      final expectation = expectLater(
        emissions,
        emitsInOrder([
          isEmpty,
          ['bob'],
        ]),
      );

      await repository.acceptFriendRequest(request, 'alice');
      await expectation;
    });
  });
}
