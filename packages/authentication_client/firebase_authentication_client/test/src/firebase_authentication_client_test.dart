// ignore_for_file: must_be_immutable
import 'dart:async';

import 'package:authentication_client/authentication_client.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_authentication_client/firebase_authentication_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class _MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class _MockFirebaseUser extends Mock implements firebase_auth.User {}

class _MockAdditionalUserInfo extends Mock
    implements firebase_auth.AdditionalUserInfo {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

@immutable
class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class _MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class _MockAuthorizationCredentialAppleID extends Mock
    implements AuthorizationCredentialAppleID {}

class _MockUserCredential extends Mock
    implements firebase_auth.UserCredential {}

class _MockFirebaseCore extends Mock
    with MockPlatformInterfaceMixin
    implements FirebasePlatform {}

class _FakeAuthCredential extends Fake
    implements firebase_auth.AuthCredential {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthenticationClient', () {
    const email = 'test@gmail.com';
    const password = 't0ps3cret42';
    const userId = 'mock-uid';

    late firebase_auth.FirebaseAuth firebaseAuth;
    late GoogleSignIn googleSignIn;
    late FirebaseAuthenticationClient firebaseAuthenticationClient;
    late AuthorizationCredentialAppleID authorizationCredentialAppleID;
    late GetAppleCredentials getAppleCredentials;
    late List<List<AppleIDAuthorizationScopes>> getAppleCredentialsCalls;

    setUpAll(() {
      registerFallbackValue(_FakeAuthCredential());
    });

    setUp(() {
      const options = FirebaseOptions(
        apiKey: 'apiKey',
        appId: 'appId',
        messagingSenderId: 'messagingSenderId',
        projectId: 'projectId',
      );
      final platformApp = FirebaseAppPlatform(defaultFirebaseAppName, options);
      final firebaseCore = _MockFirebaseCore();

      when(() => firebaseCore.apps).thenReturn([platformApp]);
      when(firebaseCore.app).thenReturn(platformApp);
      when(
        () => firebaseCore.initializeApp(
          name: defaultFirebaseAppName,
          options: options,
        ),
      ).thenAnswer((_) async => platformApp);

      Firebase.delegatePackingProperty = firebaseCore;
      firebaseAuth = _MockFirebaseAuth();
      googleSignIn = _MockGoogleSignIn();
      authorizationCredentialAppleID = _MockAuthorizationCredentialAppleID();
      getAppleCredentialsCalls = <List<AppleIDAuthorizationScopes>>[];
      getAppleCredentials = ({
        List<AppleIDAuthorizationScopes> scopes = const [],
        WebAuthenticationOptions? webAuthenticationOptions,
        String? nonce,
        String? state,
      }) async {
        getAppleCredentialsCalls.add(scopes);
        return authorizationCredentialAppleID;
      };
      firebaseAuthenticationClient = FirebaseAuthenticationClient(
        firebaseAuth: firebaseAuth,
        googleSignIn: googleSignIn,
        getAppleCredentials: getAppleCredentials,
      );
    });

    test('creates FirebaseAuth instance internally when not injected', () {
      expect(FirebaseAuthenticationClient.new, isNot(throwsException));
    });

    group('logInWithApple', () {
      setUp(() {
        when(() => firebaseAuth.signInWithCredential(any()))
            .thenAnswer((_) => Future.value(_MockUserCredential()));
        when(() => authorizationCredentialAppleID.identityToken).thenReturn('');
        when(() => authorizationCredentialAppleID.authorizationCode)
            .thenReturn('');
      });

      test('calls getAppleCredentials with correct scopes', () async {
        await firebaseAuthenticationClient.logInWithApple();
        expect(getAppleCredentialsCalls, [
          [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ]
        ]);
      });

      test('calls signInWithCredential with correct credential', () async {
        const identityToken = 'identity-token';
        const accessToken = 'access-token';
        when(() => authorizationCredentialAppleID.identityToken)
            .thenReturn(identityToken);
        when(() => authorizationCredentialAppleID.authorizationCode)
            .thenReturn(accessToken);
        await firebaseAuthenticationClient.logInWithApple();
        verify(() => firebaseAuth.signInWithCredential(any())).called(1);
      });

      test('throws LogInWithAppleFailure when exception occurs', () async {
        when(() => firebaseAuth.signInWithCredential(any()))
            .thenThrow(Exception());
        expect(
          () => firebaseAuthenticationClient.logInWithApple(),
          throwsA(isA<LogInWithAppleFailure>()),
        );
      });
    });

    group('sendPasswordResetEmail', () {
      setUp(() {
        when(
          () => firebaseAuth.sendPasswordResetEmail(email: any(named: 'email')),
        ).thenAnswer((_) => Future.value());
      });

      test('calls sendPasswordResetEmail', () async {
        await firebaseAuthenticationClient.sendPasswordResetEmail(email: email);
        verify(() => firebaseAuth.sendPasswordResetEmail(email: email))
            .called(1);
      });

      test('succeeds when sendPasswordResetEMail succeeds', () async {
        expect(
          firebaseAuthenticationClient.sendPasswordResetEmail(email: email),
          completes,
        );
      });

      test(
        'throws ResetPasswordFailure when sendPasswordResetEmail throws',
        () async {
          final firebaseAuthExceptions = {
            'invalid-email': ResetPasswordInvalidEmailFailure(Exception()),
            'user-not-found': ResetPasswordUserNotFoundFailure(Exception()),
            'default': ResetPasswordFailure(Exception()),
          };

          for (final exception in firebaseAuthExceptions.entries) {
            when(
              () => firebaseAuth.sendPasswordResetEmail(
                email: any(named: 'email'),
              ),
            ).thenThrow(
              firebase_auth.FirebaseAuthException(code: exception.key),
            );

            try {
              await firebaseAuthenticationClient.sendPasswordResetEmail(
                email: email,
              );
            } catch (e) {
              expect(e.toString(), exception.value.toString());
            }
          }
        },
      );

      test('throws ResetPasswordFailure when sendPasswordResetEmail throws',
          () async {
        when(
          () => firebaseAuth.sendPasswordResetEmail(
            email: any(named: 'email'),
          ),
        ).thenThrow(Exception());
        expect(
          firebaseAuthenticationClient.sendPasswordResetEmail(email: email),
          throwsA(isA<ResetPasswordFailure>()),
        );
      });
    });

    group('signUp', () {
      setUp(() {
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) => Future.value(_MockUserCredential()));
      });

      test('calls createUserWithEmailAndPassword', () async {
        await firebaseAuthenticationClient.signUp(
          email: email,
          password: password,
        );
        verify(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).called(1);
      });

      test('succeeds when createUserWithEmailAndPassword succeeds', () async {
        final firebaseUser = _MockFirebaseUser();
        final userCredential = _MockUserCredential();
        final additionalInfo = _MockAdditionalUserInfo();
        final emittedUsers = <User>[];

        when(() => firebaseUser.uid).thenReturn(userId);
        when(() => firebaseUser.email).thenReturn(email);
        when(() => additionalInfo.isNewUser).thenReturn(true);
        when(() => userCredential.user).thenReturn(firebaseUser);
        when(
          () => userCredential.additionalUserInfo,
        ).thenReturn(additionalInfo);
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => userCredential);
        when(
          () => firebaseAuth.authStateChanges(),
        ).thenAnswer((_) => const Stream.empty());

        final subscription = firebaseAuthenticationClient.user.listen(
          emittedUsers.add,
        );

        await expectLater(
          firebaseAuthenticationClient.signUp(email: email, password: password),
          completes,
        );

        await Future<void>.delayed(Duration.zero);

        expect(
          emittedUsers,
          equals([const User(id: userId, email: email, isNewUser: true)]),
        );

        await subscription.cancel();
      });

      test('throws correct exception based on error code', () async {
        final firebaseAuthExceptions = {
          'email-already-in-use': SignUpEmailInUseFailure(Exception()),
          'invalid-email': SignUpInvalidEmailFailure(Exception()),
          'operation-not-allowed':
              SignUpOperationNotAllowedFailure(Exception()),
          'weak-password': SignUpWeakPasswordFailure(Exception()),
          'default': SignUpFailure(Exception()),
        };

        for (final exception in firebaseAuthExceptions.entries) {
          when(
            () => firebaseAuth.createUserWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(firebase_auth.FirebaseAuthException(code: exception.key));

          try {
            await firebaseAuthenticationClient.signUp(
              email: email,
              password: password,
            );
          } catch (e) {
            expect(e.toString(), exception.value.toString());
          }
        }
      });

      test('throws SignUpFailure when createUserWithEmailAndPassword throws',
          () async {
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception());
        expect(
          firebaseAuthenticationClient.signUp(email: email, password: password),
          throwsA(isA<SignUpFailure>()),
        );
      });
    });

    group('loginWithGoogle', () {
      const accessToken = 'access-token';
      const idToken = 'id-token';

      setUp(() {
        final googleSignInAuthentication = _MockGoogleSignInAuthentication();
        final googleSignInAccount = _MockGoogleSignInAccount();
        when(() => googleSignInAuthentication.accessToken)
            .thenReturn(accessToken);
        when(() => googleSignInAuthentication.idToken).thenReturn(idToken);
        when(() => googleSignInAccount.authentication)
            .thenAnswer((_) async => googleSignInAuthentication);
        when(() => googleSignIn.signIn())
            .thenAnswer((_) async => googleSignInAccount);
        when(() => firebaseAuth.signInWithCredential(any()))
            .thenAnswer((_) => Future.value(_MockUserCredential()));
      });

      test('calls signIn authentication, and signInWithCredential', () async {
        await firebaseAuthenticationClient.logInWithGoogle();
        verify(() => googleSignIn.signIn()).called(1);
        verify(() => firebaseAuth.signInWithCredential(any())).called(1);
      });

      test('succeeds when signIn succeeds', () {
        expect(firebaseAuthenticationClient.logInWithGoogle(), completes);
      });

      test('throws LogInWithGoogleFailure when exception occurs', () async {
        when(() => firebaseAuth.signInWithCredential(any()))
            .thenThrow(Exception());
        expect(
          firebaseAuthenticationClient.logInWithGoogle(),
          throwsA(isA<LogInWithGoogleFailure>()),
        );
      });

      test('throws LogInWithGoogleCanceled when signIn returns null', () async {
        when(() => googleSignIn.signIn()).thenAnswer((_) async => null);
        expect(
          firebaseAuthenticationClient.logInWithGoogle(),
          throwsA(isA<LogInWithGoogleCanceled>()),
        );
      });
    });

    group('logInWithEmailAndPassword', () {
      setUp(() {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) => Future.value(_MockUserCredential()));
      });

      test('calls signInWithEmailAndPassword', () async {
        await firebaseAuthenticationClient.logInWithEmailAndPassword(
          email: email,
          password: password,
        );
        verify(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).called(1);
      });

      test('succeeds when signInWithEmailAndPassword succeeds', () async {
        expect(
          firebaseAuthenticationClient.logInWithEmailAndPassword(
            email: email,
            password: password,
          ),
          completes,
        );
      });

      test(
          'throws LogInWithEmailAndPasswordFailure '
          'when signInWithEmailAndPassword throws', () async {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception());
        expect(
          firebaseAuthenticationClient.logInWithEmailAndPassword(
            email: email,
            password: password,
          ),
          throwsA(isA<LogInWithEmailAndPasswordFailure>()),
        );
      });
    });

    group('logOut', () {
      test('calls signOut', () async {
        when(() => firebaseAuth.signOut()).thenAnswer((_) async {});
        when(() => googleSignIn.signOut()).thenAnswer((_) async => null);
        await firebaseAuthenticationClient.logOut();
        verify(() => firebaseAuth.signOut()).called(1);
        verify(() => googleSignIn.signOut()).called(1);
      });

      test('throws LogOutFailure when signOut throws', () async {
        when(() => firebaseAuth.signOut()).thenThrow(Exception());
        expect(
          firebaseAuthenticationClient.logOut(),
          throwsA(isA<LogOutFailure>()),
        );
      });
    });

    group('dispose', () {
      test('cancels internal subscriptions', () async {
        final controller = StreamController<firebase_auth.User>();
        final emittedUsers = <User>[];
        final firebaseUser = _MockFirebaseUser();

        when(() => firebaseUser.uid).thenReturn(userId);
        when(() => firebaseUser.email).thenReturn(email);
        when(
          () => firebaseAuth.authStateChanges(),
        ).thenAnswer((_) => controller.stream);

        final subscription = firebaseAuthenticationClient.user.listen(
          emittedUsers.add,
        );
        firebaseAuthenticationClient.dispose();

        controller.add(firebaseUser);
        await Future<void>.delayed(Duration.zero);

        expect(emittedUsers, isEmpty);

        await subscription.cancel();
      });
    });

    group('user', () {
      const newUser = User(id: userId, email: email, isNewUser: true);
      const returningUser = User(id: userId, email: email);
      test('emits User.unauthenticated when firebase user is null', () async {
        when(() => firebaseAuth.authStateChanges()).thenAnswer(
          (_) => Stream.value(null),
        );
        await expectLater(
          firebaseAuthenticationClient.user,
          emitsInOrder(const <User>[User.unauthenticated]),
        );
      });

      test('emits new user when firebase user is not null', () async {
        final firebaseUser = _MockFirebaseUser();
        final userCredential = _MockUserCredential();
        final additionalInfo = _MockAdditionalUserInfo();
        final emittedUsers = <User>[];

        when(() => firebaseUser.uid).thenReturn(userId);
        when(() => firebaseUser.email).thenReturn(email);
        when(() => additionalInfo.isNewUser).thenReturn(true);
        when(() => userCredential.user).thenReturn(firebaseUser);
        when(
          () => userCredential.additionalUserInfo,
        ).thenReturn(additionalInfo);
        when(() => firebaseAuth.authStateChanges()).thenAnswer(
          (_) => const Stream.empty(),
        );
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => userCredential);
        final subscription = firebaseAuthenticationClient.user.listen(
          emittedUsers.add,
        );
        await firebaseAuthenticationClient.logInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await Future<void>.delayed(Duration.zero);
        expect(emittedUsers, equals([newUser]));
        await subscription.cancel();
      });

      test('emits returning user when firebase user is not null', () async {
        final firebaseUser = _MockFirebaseUser();
        when(() => firebaseUser.uid).thenReturn(userId);
        when(() => firebaseUser.email).thenReturn(email);
        when(() => firebaseUser.photoURL).thenReturn(null);
        when(() => firebaseAuth.authStateChanges()).thenAnswer(
          (_) => Stream.value(firebaseUser),
        );
        await expectLater(
          firebaseAuthenticationClient.user,
          emitsInOrder(const <User>[returningUser]),
        );
      });
    });
  });
}
