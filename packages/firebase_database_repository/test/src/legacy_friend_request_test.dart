// Verifies acceptFriendRequest's catch block rethrows a rules-layer
// permission-denied FirebaseException as the typed LegacyFriendRequestException
// instead of the generic wrapped Exception. fake_cloud_firestore has no rules
// engine (see friend_request_lifecycle_test.dart's coverage note), so a mock
// FirebaseFirestore is used here purely to inject a thrown FirebaseException
// at the first read the method performs. CollectionReference/DocumentReference
// are sealed in cloud_firestore, so only the (unsealed) FirebaseFirestore
// itself is mocked — `collection('users')` throws directly rather than
// returning a mocked reference chain.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('acceptFriendRequest legacy-request mapping', () {
    final request = FriendRequestModel(
      id: 'bob_alice',
      senderId: 'bob',
      senderName: 'Bob',
      receiverId: 'alice',
      status: 'pending',
      timestamp: DateTime(2024),
    );

    test(
        'rethrows FirebaseException permission-denied as '
        'LegacyFriendRequestException', () async {
      final firestore = _MockFirebaseFirestore();
      when(() => firestore.collection('users')).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );

      final repository = FirebaseDatabaseRepository(firebase: firestore);

      expect(
        () => repository.acceptFriendRequest(request, 'alice'),
        throwsA(isA<LegacyFriendRequestException>()),
      );
    });

    test('other failures still throw the generic Exception', () async {
      final firestore = _MockFirebaseFirestore();
      when(() => firestore.collection('users')).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      final repository = FirebaseDatabaseRepository(firebase: firestore);

      await expectLater(
        repository.acceptFriendRequest(request, 'alice'),
        throwsA(
          allOf(
            isA<Exception>(),
            isNot(isA<LegacyFriendRequestException>()),
          ),
        ),
      );
    });

    test('happy path against fake_cloud_firestore is unaffected', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('bob').set({
        'username': 'Bob',
        'imageUrl': '',
      });
      await firestore.collection('users').doc('alice').set({
        'username': 'Alice',
        'imageUrl': '',
      });
      final repository = FirebaseDatabaseRepository(firebase: firestore);

      await repository.acceptFriendRequest(request, 'alice');

      expect(
        (await firestore.doc('friends/alice/friendList/bob').get()).exists,
        isTrue,
      );
    });
  });
}
