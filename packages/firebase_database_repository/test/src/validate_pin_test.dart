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
    when(() => functions.httpsCallable('validatePin')).thenReturn(callable);
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

  test('valid response maps to PinValid', () async {
    stubResult({'valid': true});
    final result = await repository.validatePin(
      targetUserId: 'friend1',
      pin: '0742',
    );
    expect(result, const PinValid());
    verify(
      () => callable.call<dynamic>({'targetUserId': 'friend1', 'pin': '0742'}),
    ).called(1);
  });

  test('invalid response maps to PinInvalid with attemptsRemaining', () async {
    stubResult({'valid': false, 'attemptsRemaining': 3});
    final result = await repository.validatePin(
      targetUserId: 'friend1',
      pin: '9999',
    );
    expect(result, const PinInvalid(attemptsRemaining: 3));
  });

  test('resource-exhausted maps to PinLockedOut with lockedUntil', () async {
    final until = DateTime.now().add(const Duration(minutes: 15));
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(
        code: 'resource-exhausted',
        message: 'locked',
        details: {'lockedUntilMillis': until.millisecondsSinceEpoch},
      ),
    );
    final result = await repository.validatePin(
      targetUserId: 'friend1',
      pin: '0742',
    );
    expect(result, isA<PinLockedOut>());
    expect(
      (result as PinLockedOut).lockedUntil.millisecondsSinceEpoch,
      until.millisecondsSinceEpoch,
    );
  });

  test('unavailable/internal errors map to PinCheckUnavailable', () async {
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(code: 'unavailable', message: 'offline'),
    );
    expect(
      await repository.validatePin(targetUserId: 'f', pin: '0742'),
      const PinCheckUnavailable(),
    );
  });

  test('failed-precondition maps to PinNotSet', () async {
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(code: 'failed-precondition', message: 'no pin'),
    );
    expect(
      await repository.validatePin(targetUserId: 'f', pin: '0742'),
      const PinNotSet(),
    );
  });
}
