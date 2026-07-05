// Coverage note: fake_cloud_firestore has no rules engine, so the actual
// Firestore security rule enforcement (deletes of nonexistent/declined
// friendRequests docs denied; users/{uid}/blocks owner-only) is covered by
// Task 3's rules tests. This file exercises the repository's own guard
// logic: it reads the deterministic request docs first and only includes
// existing-and-pending ones in the delete batch, so it never even attempts
// a delete that the rules would deny.
import 'package:cloud_firestore/cloud_firestore.dart';
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

  group('blockUser', () {
    const target = BlockedUserModel(
      userId: 'bob',
      username: 'Bob',
      imageUrl: 'http://x/bob.png',
    );

    test('writes the block doc with denormalized fields + blockedAt', () async {
      await repository.blockUser(currentUserId: 'alice', target: target);

      final blockDoc = await firestore.doc('users/alice/blocks/bob').get();
      expect(blockDoc.exists, isTrue);
      expect(blockDoc.data()!['username'], 'Bob');
      expect(blockDoc.data()!['imageUrl'], 'http://x/bob.png');
      expect(blockDoc.data()!['blockedAt'], isA<Timestamp>());
    });

    test('removes both friendship edges', () async {
      await firestore
          .doc('friends/alice/friendList/bob')
          .set({'userId': 'bob'});
      await firestore
          .doc('friends/bob/friendList/alice')
          .set({'userId': 'alice'});

      await repository.blockUser(currentUserId: 'alice', target: target);

      expect(
        (await firestore.doc('friends/alice/friendList/bob').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.doc('friends/bob/friendList/alice').get()).exists,
        isFalse,
      );
    });

    test('deletes both deterministic request docs when pending', () async {
      await firestore.doc('friendRequests/alice_bob').set({
        'id': 'alice_bob',
        'senderId': 'alice',
        'receiverId': 'bob',
        'status': 'pending',
      });
      await firestore.doc('friendRequests/bob_alice').set({
        'id': 'bob_alice',
        'senderId': 'bob',
        'receiverId': 'alice',
        'status': 'pending',
      });

      await repository.blockUser(currentUserId: 'alice', target: target);

      expect(
        (await firestore.doc('friendRequests/alice_bob').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.doc('friendRequests/bob_alice').get()).exists,
        isFalse,
      );
    });

    test('leaves a declined deterministic doc alone (not deleted)', () async {
      await firestore.doc('friendRequests/alice_bob').set({
        'id': 'alice_bob',
        'senderId': 'alice',
        'receiverId': 'bob',
        'status': 'declined',
      });

      await repository.blockUser(currentUserId: 'alice', target: target);

      final doc = await firestore.doc('friendRequests/alice_bob').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['status'], 'declined');
    });

    test('handles nonexistent deterministic docs without error', () async {
      await repository.blockUser(currentUserId: 'alice', target: target);

      expect(
        (await firestore.doc('friendRequests/alice_bob').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.doc('friendRequests/bob_alice').get()).exists,
        isFalse,
      );
    });

    test(
        'deletes a seeded legacy pending request (random id, '
        'senderId target -> me)', () async {
      await firestore
          .collection('friendRequests')
          .doc('legacyRandomId123')
          .set({
        'id': 'legacyRandomId123',
        'senderId': 'bob',
        'receiverId': 'alice',
        'status': 'pending',
      });

      await repository.blockUser(currentUserId: 'alice', target: target);

      expect(
        (await firestore.doc('friendRequests/legacyRandomId123').get()).exists,
        isFalse,
      );
    });

    test(
        'deletes a seeded legacy pending request in the other direction '
        '(me -> target)', () async {
      await firestore
          .collection('friendRequests')
          .doc('legacyRandomId456')
          .set({
        'id': 'legacyRandomId456',
        'senderId': 'alice',
        'receiverId': 'bob',
        'status': 'pending',
      });

      await repository.blockUser(currentUserId: 'alice', target: target);

      expect(
        (await firestore.doc('friendRequests/legacyRandomId456').get()).exists,
        isFalse,
      );
    });
  });

  group('unblockUser', () {
    test('removes only the block doc', () async {
      await firestore.doc('users/alice/blocks/bob').set({
        'userId': 'bob',
        'username': 'Bob',
        'imageUrl': '',
        'blockedAt': FieldValue.serverTimestamp(),
      });

      await repository.unblockUser(
        currentUserId: 'alice',
        targetUserId: 'bob',
      );

      expect(
        (await firestore.doc('users/alice/blocks/bob').get()).exists,
        isFalse,
      );
    });

    test('does not resurrect the friendship edges', () async {
      await firestore.doc('users/alice/blocks/bob').set({
        'userId': 'bob',
        'username': 'Bob',
        'imageUrl': '',
        'blockedAt': FieldValue.serverTimestamp(),
      });

      await repository.unblockUser(
        currentUserId: 'alice',
        targetUserId: 'bob',
      );

      expect(
        (await firestore.doc('friends/alice/friendList/bob').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.doc('friends/bob/friendList/alice').get()).exists,
        isFalse,
      );
    });
  });

  group('getBlockedUsers', () {
    test('streams seeded docs newest-first', () async {
      final earlier = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      final later = Timestamp.now();

      await firestore.doc('users/alice/blocks/bob').set({
        'userId': 'bob',
        'username': 'Bob',
        'imageUrl': '',
        'blockedAt': earlier,
      });
      await firestore.doc('users/alice/blocks/carol').set({
        'userId': 'carol',
        'username': 'Carol',
        'imageUrl': '',
        'blockedAt': later,
      });

      final result = await repository.getBlockedUsers('alice').first;

      expect(result.map((u) => u.userId), ['carol', 'bob']);
    });
  });
}
