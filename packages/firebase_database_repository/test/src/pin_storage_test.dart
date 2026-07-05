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

  group('salt helpers', () {
    test('generateSalt returns 32 hex chars and is random', () {
      final a = FirebaseDatabaseRepository.generateSalt();
      final b = FirebaseDatabaseRepository.generateSalt();
      expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(a, isNot(b));
    });

    test('saltedPinHash is deterministic and salt-sensitive', () {
      final h1 = FirebaseDatabaseRepository.saltedPinHash('0742', 'aa');
      expect(h1, FirebaseDatabaseRepository.saltedPinHash('0742', 'aa'));
      expect(h1, isNot(FirebaseDatabaseRepository.saltedPinHash('0742', 'bb')));
      expect(h1, isNot(FirebaseDatabaseRepository.hashPin('0742')));
    });
  });

  group('setPin', () {
    test('writes salted credentials, sets hasPin, removes legacy field',
        () async {
      await firestore
          .collection('users')
          .doc('u1')
          .set({'username': 'josh', 'pin': 'legacyhash'});

      await repository.setPin('u1', '0742');

      final creds = await firestore
          .doc('users/u1/private/credentials')
          .get();
      final salt = creds.data()!['salt'] as String;
      expect(
        creds.data()!['pinHash'],
        FirebaseDatabaseRepository.saltedPinHash('0742', salt),
      );

      final profile = await firestore.doc('users/u1').get();
      expect(profile.data()!['hasPin'], isTrue);
      expect(profile.data()!.containsKey('pin'), isFalse);
      expect(profile.data()!['username'], 'josh');
    });
  });

  group('migrateLegacyPin', () {
    test('moves legacy hash into private credentials with null salt',
        () async {
      final legacyHash = FirebaseDatabaseRepository.hashPin('0742');
      await firestore.collection('users').doc('u1').set({'pin': legacyHash});

      await repository.migrateLegacyPin('u1');
      // migrateLegacyPin fires the batch commit without awaiting it (see
      // the offline-hang fix in FirebaseDatabaseRepository), so give the
      // microtask queue a turn before asserting on its effects.
      await Future<void>.delayed(Duration.zero);

      final creds =
          await firestore.doc('users/u1/private/credentials').get();
      expect(creds.data()!['pinHash'], legacyHash);
      expect(creds.data()!['salt'], isNull);

      final profile = await firestore.doc('users/u1').get();
      expect(profile.data()!['hasPin'], isTrue);
      expect(profile.data()!.containsKey('pin'), isFalse);
    });

    test('no-ops when there is nothing to migrate', () async {
      await firestore.collection('users').doc('u1').set({'username': 'j'});
      await repository.migrateLegacyPin('u1');
      final creds =
          await firestore.doc('users/u1/private/credentials').get();
      expect(creds.exists, isFalse);
    });

    test('does not overwrite already-migrated credentials', () async {
      await firestore.doc('users/u1/private/credentials').set({
        'pinHash': 'saltedHash',
        'salt': 'realsalt',
      });
      await firestore
          .collection('users')
          .doc('u1')
          .set({'pin': 'staleLegacy'});

      await repository.migrateLegacyPin('u1');
      // See note above: the batch commit is fire-and-forget.
      await Future<void>.delayed(Duration.zero);

      final creds =
          await firestore.doc('users/u1/private/credentials').get();
      expect(creds.data()!['pinHash'], 'saltedHash');
      final profile = await firestore.doc('users/u1').get();
      expect(profile.data()!.containsKey('pin'), isFalse);
      expect(profile.data()!['hasPin'], isTrue);
    });
  });

  group('hasPin', () {
    test('true for hasPin flag, true for legacy field, false otherwise',
        () async {
      await firestore.collection('users').doc('a').set({'hasPin': true});
      await firestore.collection('users').doc('b').set({'pin': 'hash'});
      await firestore.collection('users').doc('c').set({'username': 'x'});
      expect(await repository.hasPin('a'), isTrue);
      expect(await repository.hasPin('b'), isTrue);
      expect(await repository.hasPin('c'), isFalse);
    });
  });
}
