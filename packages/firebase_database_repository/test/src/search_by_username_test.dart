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
    when(() => functions.httpsCallable('searchByUsername'))
        .thenReturn(callable);
    repository = FirebaseDatabaseRepository(
      firebase: FakeFirebaseFirestore(),
      functions: functions,
    );
  });

  void stubResult(Map<String, dynamic> data) {
    final result = _MockResult();
    when(() => result.data).thenReturn(data);
    when(() => callable.call<dynamic>(any<Map<String, dynamic>>()))
        .thenAnswer((_) async => result);
  }

  test('maps multiple matches to UserSearchMatch with their relationships',
      () async {
    stubResult({
      'matches': [
        {
          'user': {
            'id': 'josh',
            'username': 'Josh',
            'imageUrl': 'http://x/y.png',
            'friendCode': 'YETI-JOSH',
          },
          'relationship': 'none',
        },
        {
          'user': {
            'id': 'john',
            'username': 'John',
            'imageUrl': '',
            'friendCode': 'YETI-JOHN',
          },
          'relationship': 'friends',
        },
      ],
    });

    final result = await repository.searchByUsername('jo');

    expect(result, hasLength(2));
    expect(result[0].user.id, 'josh');
    expect(result[0].relationship, RelationshipStatus.none);
    expect(result[1].user.id, 'john');
    expect(result[1].relationship, RelationshipStatus.friends);
    verify(() => callable.call<dynamic>({'query': 'jo'})).called(1);
  });

  test('empty matches payload maps to an empty list', () async {
    stubResult({'matches': <dynamic>[]});

    final result = await repository.searchByUsername('zz');

    expect(result, isEmpty);
  });

  test('invalid-argument throws ArgumentError', () async {
    when(() => callable.call<dynamic>(any<Map<String, dynamic>>())).thenThrow(
      FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'query must be at least 2 characters.',
      ),
    );

    expect(
      () => repository.searchByUsername('j'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('other FirebaseFunctionsException throws a plain Exception', () async {
    when(() => callable.call<dynamic>(any<Map<String, dynamic>>())).thenThrow(
      FirebaseFunctionsException(code: 'internal', message: 'boom'),
    );

    expect(
      () => repository.searchByUsername('jo'),
      throwsA(isA<Exception>()),
    );
  });
}
