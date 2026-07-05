import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock implements HttpsCallableResult<dynamic> {}

void main() {
  late _MockFunctions functions;
  late _MockCallable callable;
  late FirebaseDatabaseRepository repository;

  setUp(() {
    functions = _MockFunctions();
    callable = _MockCallable();
    when(() => functions.httpsCallable('searchByFriendCode'))
        .thenReturn(callable);
    repository = FirebaseDatabaseRepository(
      firebase: FakeFirebaseFirestore(),
      functions: functions,
    );
  });

  void stubResult(Map<String, dynamic> data) {
    final result = _MockResult();
    when(() => result.data).thenReturn(data);
    when(() => callable.call<dynamic>(any())).thenAnswer((_) async => result);
  }

  test(
      'found:true payload maps to FriendSearchResult with '
      'RelationshipStatus.pendingSent', () async {
    stubResult({
      'found': true,
      'user': {
        'id': 'target',
        'username': 'Target',
        'imageUrl': 'http://x/y.png',
        'friendCode': 'YETI-A3F9',
      },
      'relationship': 'pendingSent',
    });

    final result = await repository.searchByFriendCode('yeti-a3f9');

    expect(result.found, isTrue);
    expect(result.user?.id, 'target');
    expect(result.user?.username, 'Target');
    expect(result.user?.imageUrl, 'http://x/y.png');
    expect(result.user?.friendCode, 'YETI-A3F9');
    expect(result.relationship, RelationshipStatus.pendingSent);
    verify(
      () => callable.call<dynamic>({'code': 'yeti-a3f9'}),
    ).called(1);
  });

  test('found:false payload maps to a not-found FriendSearchResult', () async {
    stubResult({'found': false});

    final result = await repository.searchByFriendCode('YETI-ZZZZ');

    expect(result, const FriendSearchResult(found: false));
  });

  test('unavailable throws', () async {
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(code: 'unavailable', message: 'offline'),
    );

    expect(
      () => repository.searchByFriendCode('YETI-A3F9'),
      throwsA(isA<Exception>()),
    );
  });

  test('invalid-argument throws ArgumentError', () async {
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'code is required',
      ),
    );

    expect(
      () => repository.searchByFriendCode(''),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('other FirebaseFunctionsException throws (not found:false)', () async {
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(
        code: 'internal',
        message: 'boom',
      ),
    );

    expect(
      () => repository.searchByFriendCode('YETI-A3F9'),
      throwsA(isA<Exception>()),
    );
  });

  test('found:true maps friends relationship correctly', () async {
    stubResult({
      'found': true,
      'user': {
        'id': 'target',
        'username': 'Target',
        'imageUrl': '',
        'friendCode': 'YETI-A3F9',
      },
      'relationship': 'friends',
    });

    final result = await repository.searchByFriendCode('YETI-A3F9');

    expect(result.relationship, RelationshipStatus.friends);
  });
}
