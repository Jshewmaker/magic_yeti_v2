// Coverage note: fake_cloud_firestore has no rules engine, so the
// permission-denied path in addFriendRequest (a blocked sender's create is
// denied by Firestore security rules, and the repository silently maps that
// denial to FriendRequestResult.sent for concealment) cannot be exercised
// here by throwing a real rules-layer FirebaseException. That wire-level
// denial is covered by Task 3's rules tests (packages/.../test/firestore
// .rules tests, or equivalent), which assert the rules themselves reject the
// write. The client-side catch/mapping in this file is a 3-line
// `on FirebaseException catch (e) { if (e.code == 'permission-denied') ... }`
// block verified by code review and by the manual/widget flow rather than by
// a unit test that fakes a thrown FirebaseException here.
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

  group('addFriendRequest', () {
    test('new requests use the deterministic doc id and id field', () async {
      final result =
          await repository.addFriendRequest('alice', 'Alice', 'bob');
      expect(result, FriendRequestResult.sent);
      final doc = await firestore.doc('friendRequests/alice_bob').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['id'], 'alice_bob');
      expect(doc.data()!['status'], 'pending');
      expect(doc.data()!['senderId'], 'alice');
      expect(doc.data()!['receiverId'], 'bob');
    });

    test('re-send onto an existing pending returns alreadyPending', () async {
      await repository.addFriendRequest('alice', 'Alice', 'bob');
      expect(
        await repository.addFriendRequest('alice', 'Alice', 'bob'),
        FriendRequestResult.alreadyPending,
      );
    });

    test('declined doc suppresses re-send silently as sent', () async {
      await repository.addFriendRequest('alice', 'Alice', 'bob');
      await repository.declineFriendRequest('alice_bob');
      final result =
          await repository.addFriendRequest('alice', 'Alice', 'bob');
      expect(result, FriendRequestResult.sent);
      // Still declined — no new pending doc, receiver never sees it again.
      final doc = await firestore.doc('friendRequests/alice_bob').get();
      expect(doc.data()!['status'], 'declined');
    });

    test('decline retains the doc with status declined', () async {
      await repository.addFriendRequest('alice', 'Alice', 'bob');
      await repository.declineFriendRequest('alice_bob');
      final doc = await firestore.doc('friendRequests/alice_bob').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['status'], 'declined');
    });

    test('reverse pending auto-accepts and removes both request docs',
        () async {
      await firestore.collection('users').doc('alice').set({'username': 'a'});
      await firestore.collection('users').doc('bob').set({'username': 'b'});
      await repository.addFriendRequest('bob', 'Bob', 'alice');
      final result =
          await repository.addFriendRequest('alice', 'Alice', 'bob');
      expect(result, FriendRequestResult.autoAccepted);
      expect(
        (await firestore.doc('friends/alice/friendList/bob').get()).exists,
        isTrue,
      );
      expect(
        (await firestore.doc('friends/bob/friendList/alice').get()).exists,
        isTrue,
      );
      expect(
        (await firestore.doc('friendRequests/bob_alice').get()).exists,
        isFalse,
      );
    });

    test(
        'reverse pending wins over declined suppression: '
        'auto-accepts and leaves the declined doc untouched', () async {
      await firestore.collection('users').doc('alice').set({'username': 'a'});
      await firestore.collection('users').doc('bob').set({'username': 'b'});
      // Alice sent Bob a request; Bob declined it.
      await repository.addFriendRequest('alice', 'Alice', 'bob');
      await repository.declineFriendRequest('alice_bob');
      // Bob later sends Alice a request (reverse-direction pending).
      await repository.addFriendRequest('bob', 'Bob', 'alice');
      // Alice taps Accept on Bob's request from the search card — this
      // re-invokes addFriendRequest in the alice->bob direction. The
      // reverse-pending (bob_alice) must win over the own-doc declined
      // short-circuit (alice_bob) and auto-accept.
      final result =
          await repository.addFriendRequest('alice', 'Alice', 'bob');
      expect(result, FriendRequestResult.autoAccepted);
      expect(
        (await firestore.doc('friends/alice/friendList/bob').get()).exists,
        isTrue,
      );
      expect(
        (await firestore.doc('friends/bob/friendList/alice').get()).exists,
        isTrue,
      );
      expect(
        (await firestore.doc('friendRequests/bob_alice').get()).exists,
        isFalse,
      );
      // The old declined doc is untouched — not deleted, not resurrected.
      final declinedDoc =
          await firestore.doc('friendRequests/alice_bob').get();
      expect(declinedDoc.exists, isTrue);
      expect(declinedDoc.data()!['status'], 'declined');
    });

    test('getFriendRequests still filters to pending only', () async {
      await repository.addFriendRequest('alice', 'Alice', 'bob');
      await repository.addFriendRequest('carol', 'Carol', 'bob');
      await repository.declineFriendRequest('alice_bob');
      final requests = await repository.getFriendRequests('bob');
      expect(requests.map((r) => r.senderId), ['carol']);
    });
  });
}
