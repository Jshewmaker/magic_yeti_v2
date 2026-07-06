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

  test('derives usernameLower from username on write, ignoring any '
      'usernameLower already on the model', () async {
    const profile = UserProfileModel(
      id: 'u1',
      username: 'Josh',
      usernameLower: 'stale-value',
    );

    await repository.updateUserProfile('u1', profile);

    final doc = await firestore.doc('users/u1').get();
    expect(doc.data()!['usernameLower'], 'josh');
  });

  test('a null username clears any stale usernameLower rather than keeping '
      'it', () async {
    const profile = UserProfileModel(id: 'u1', usernameLower: 'stale-value');

    await repository.updateUserProfile('u1', profile);

    final doc = await firestore.doc('users/u1').get();
    expect(doc.data()!.containsKey('usernameLower'), isFalse);
  });
}
