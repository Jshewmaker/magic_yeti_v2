// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:authentication_client/authentication_client.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_repository/user_repository.dart';

class _MockAuthenticationClient extends Mock implements AuthenticationClient {}

class _FakeSignUpFailure extends Fake implements SignUpFailure {}

class _FakeResetPasswordFailure extends Fake implements ResetPasswordFailure {}

class _FakeLogInWithAppleFailure extends Fake
    implements LogInWithAppleFailure {}

class _FakeLogInWithGoogleFailure extends Fake
    implements LogInWithGoogleFailure {}

class _FakeLogInWithGoogleCanceled extends Fake
    implements LogInWithGoogleCanceled {}

class _FakeLogInWithEmailAndPasswordFailure extends Fake
    implements LogInWithEmailAndPasswordFailure {}

class _FakeLogOutFailure extends Fake implements LogOutFailure {}

class _FakeDeleteAccountFailure extends Fake implements DeleteAccountFailure {}

class _FakeFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  group('UserRepository', () {
    late AuthenticationClient authenticationClient;
    late UserRepository userRepository;
    late FirebaseDatabaseRepository firebaseDatabaseRepository;

    setUp(() {
      authenticationClient = _MockAuthenticationClient();
      firebaseDatabaseRepository = _FakeFirebaseDatabaseRepository();
      userRepository = UserRepository(
        authenticationClient: authenticationClient,
        firebaseDatabaseRepository: firebaseDatabaseRepository,
      );
    });

    group('user', () {
      test('calls user on AuthenticationClient', () {
        when(() => authenticationClient.user).thenAnswer(
          (_) => const Stream.empty(),
        );
        userRepository.user;
        verify(() => authenticationClient.user).called(1);
      });
    });

    group('signUp', () {
      test(
          'calls AuthenticationClient signUp '
          'with email and password', () async {
        when(
          () => authenticationClient.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {});
        await userRepository.signUp(
          email: 'ben_franklin@upenn.edu',
          password: 'BenFranklin123',
        );
        verify(
          () => authenticationClient.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).called(1);
      });

      test('rethrows SignUpFailure', () async {
        final exception = _FakeSignUpFailure();
        when(
          () => authenticationClient.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(exception);
        expect(
          () => userRepository.signUp(
            email: 'ben_franklin@upenn.edu',
            password: 'BenFranklin123',
          ),
          throwsA(exception),
        );
      });

      test('throws SignUpFailure on generic exception', () async {
        when(
          () => authenticationClient.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception());
        expect(
          () => userRepository.signUp(
            email: 'ben_franklin@upenn.edu',
            password: 'BenFranklin123',
          ),
          throwsA(isA<SignUpFailure>()),
        );
      });
    });

    group('sendPasswordResetEmail', () {
      test('calls sendPasswordResetEmail with email on AuthenticationClient',
          () async {
        when(
          () => authenticationClient.sendPasswordResetEmail(
            email: any(named: 'email'),
          ),
        ).thenAnswer((_) async {});
        await userRepository.sendPasswordResetEmail(
          email: 'ben_franklin@upenn.edu',
        );
        verify(
          () => authenticationClient.sendPasswordResetEmail(
            email: any(named: 'email'),
          ),
        ).called(1);
      });

      test('rethrows ResetPasswordFailure', () async {
        final exception = _FakeResetPasswordFailure();
        when(
          () => authenticationClient.sendPasswordResetEmail(
            email: any(named: 'email'),
          ),
        ).thenThrow(exception);
        expect(
          () => userRepository.sendPasswordResetEmail(
            email: 'ben_franklin@upenn.edu',
          ),
          throwsA(exception),
        );
      });

      test('throws ResetPasswordFailure on generic exception', () async {
        when(
          () => authenticationClient.sendPasswordResetEmail(
            email: any(named: 'email'),
          ),
        ).thenThrow(Exception());
        expect(
          () => userRepository.sendPasswordResetEmail(
            email: 'ben_franklin@upenn.edu',
          ),
          throwsA(isA<ResetPasswordFailure>()),
        );
      });
    });

    group('logInWithApple', () {
      test('calls logInWithApple on AuthenticationClient', () async {
        when(
          () => authenticationClient.logInWithApple(),
        ).thenAnswer((_) async {});
        await userRepository.logInWithApple();
        verify(() => authenticationClient.logInWithApple()).called(1);
      });

      test('rethrows LogInWithAppleFailure', () async {
        final exception = _FakeLogInWithAppleFailure();
        when(
          () => authenticationClient.logInWithApple(),
        ).thenThrow(exception);
        expect(
          () => userRepository.logInWithApple(),
          throwsA(exception),
        );
      });

      test('throws LogInWithAppleFailure on generic exception', () async {
        when(
          () => authenticationClient.logInWithApple(),
        ).thenThrow(Exception());
        expect(
          () => userRepository.logInWithApple(),
          throwsA(isA<LogInWithAppleFailure>()),
        );
      });
    });

    group('logInWithGoogle', () {
      test('calls logInWithGoogle on AuthenticationClient', () async {
        when(
          () => authenticationClient.logInWithGoogle(),
        ).thenAnswer((_) async {});
        await userRepository.logInWithGoogle();
        verify(() => authenticationClient.logInWithGoogle()).called(1);
      });

      test('rethrows LogInWithGoogleFailure', () async {
        final exception = _FakeLogInWithGoogleFailure();
        when(() => authenticationClient.logInWithGoogle()).thenThrow(exception);
        expect(() => userRepository.logInWithGoogle(), throwsA(exception));
      });

      test('rethrows LogInWithGoogleCanceled', () async {
        final exception = _FakeLogInWithGoogleCanceled();
        when(() => authenticationClient.logInWithGoogle()).thenThrow(exception);
        expect(userRepository.logInWithGoogle(), throwsA(exception));
      });

      test('throws LogInWithGoogleFailure on generic exception', () async {
        when(
          () => authenticationClient.logInWithGoogle(),
        ).thenThrow(Exception());
        expect(
          () => userRepository.logInWithGoogle(),
          throwsA(isA<LogInWithGoogleFailure>()),
        );
      });
    });

    group('onGoogleUserAuthorized', () {
      test('calls onGoogleUserAuthorized on Authentication client', () {
        userRepository.onGoogleUserAuthorized();

        verify(
          () => authenticationClient.onGoogleUserAuthorized(),
        ).called(1);
      });
    });

    group('logInWithEmailAndPassWord', () {
      test(
          'calls logInWithEmailAndPassWord '
          'with email and password on AuthenticationClient', () async {
        when(
          () => authenticationClient.logInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {});
        await userRepository.logInWithEmailAndPassword(
          email: 'ben_franklin@upenn.edu',
          password: 'BenFranklin123',
        );
        verify(
          () => authenticationClient.logInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).called(1);
      });

      test('rethrows LogInWithEmailAndPasswordFailure', () async {
        final exception = _FakeLogInWithEmailAndPasswordFailure();
        when(
          () => authenticationClient.logInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(exception);
        expect(
          () => userRepository.logInWithEmailAndPassword(
            email: 'ben_franklin@upenn.edu',
            password: 'BenFranklin123',
          ),
          throwsA(exception),
        );
      });

      test(
          'throws LogInWithEmailAndPasswordFailure '
          'on generic exception', () async {
        when(
          () => authenticationClient.logInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception());
        expect(
          () => userRepository.logInWithEmailAndPassword(
            email: 'ben_franklin@upenn.edu',
            password: 'BenFranklin123',
          ),
          throwsA(isA<LogInWithEmailAndPasswordFailure>()),
        );
      });
    });

    group('logOut', () {
      test('calls logOut on AuthenticationClient', () async {
        when(() => authenticationClient.logOut()).thenAnswer((_) async {});
        await userRepository.logOut();
        verify(() => authenticationClient.logOut()).called(1);
      });

      test('rethrows LogOutFailure', () async {
        final exception = _FakeLogOutFailure();
        when(() => authenticationClient.logOut()).thenThrow(exception);
        expect(() => userRepository.logOut(), throwsA(exception));
      });

      test('throws LogOutFailure on generic exception', () async {
        when(() => authenticationClient.logOut()).thenThrow(Exception());
        expect(() => userRepository.logOut(), throwsA(isA<LogOutFailure>()));
      });
    });

    group('deleteAccount', () {
      test('calls deleteAccount on AuthenticationClient', () async {
        when(() => authenticationClient.deleteAccount())
            .thenAnswer((_) async {});
        await userRepository.deleteAccount();
        verify(() => authenticationClient.deleteAccount()).called(1);
      });

      test('rethrows DeleteAccountFailure', () async {
        final exception = _FakeDeleteAccountFailure();
        when(() => authenticationClient.deleteAccount()).thenThrow(exception);
        expect(() => userRepository.deleteAccount(), throwsA(exception));
      });

      test('throws DeleteAccountFailure on generic exception', () async {
        when(() => authenticationClient.deleteAccount()).thenThrow(Exception());
        expect(
          () => userRepository.deleteAccount(),
          throwsA(isA<DeleteAccountFailure>()),
        );
      });
    });
  });
}
