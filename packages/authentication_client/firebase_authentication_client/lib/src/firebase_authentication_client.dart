import 'dart:async';

import 'package:authentication_client/authentication_client.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_authentication_client/src/lock.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/subjects.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Signature for [SignInWithApple.getAppleIDCredential].
typedef GetAppleCredentials = Future<AuthorizationCredentialAppleID> Function({
  required List<AppleIDAuthorizationScopes> scopes,
  WebAuthenticationOptions webAuthenticationOptions,
  String nonce,
  String state,
});

/// {@template firebase_authentication_client}
/// A Firebase implementation of the [AuthenticationClient] interface.
/// {@endtemplate}
class FirebaseAuthenticationClient implements AuthenticationClient {
  /// {@macro firebase_authentication_client}
  FirebaseAuthenticationClient({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    GetAppleCredentials? getAppleCredentials,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard(),
        _getAppleCredentials =
            getAppleCredentials ?? SignInWithApple.getAppleIDCredential,
        _userController = BehaviorSubject<User>();

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final GetAppleCredentials _getAppleCredentials;
  final _lock = Lock();
  final BehaviorSubject<User> _userController;
  StreamSubscription<firebase_auth.User?>? _firebaseUserSubscription;

  /// Stream of [User] which will emit the current user when
  /// the authentication state changes.
  ///
  /// Emits [User.unauthenticated] if the user is not authenticated.
  @override
  BehaviorSubject<User> get user {
    _firebaseUserSubscription ??= _firebaseAuth
        .authStateChanges()
        .asyncMap<firebase_auth.User?>(anonymouslySignIn)
        .listen((firebaseUser) {
      if (_lock.isLocked) return;

      _userController.add(
        firebaseUser == null ? User.unauthenticated : firebaseUser.toUser(),
      );
    });

    return _userController;
  }

  /// Creates a new user with the provided [email] and [password].
  ///
  /// Throws:
  /// - [SignUpEmailInUseFailure] when [email] is already in use.
  /// - [SignUpInvalidEmailFailure] when [email] is invalid.
  /// - [SignUpOperationNotAllowedFailure] when operation is not allowed.
  /// - [SignUpWeakPasswordFailure] when [password] is too weak.
  /// - [SignUpFailure] when unknown error occurs.
  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      final userCredential = await _lock.run(
        () => _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
      _userController.add(userCredential.toUser);
    } on firebase_auth.FirebaseAuthException catch (error, stackTrace) {
      switch (error.code) {
        case 'email-already-in-use':
          Error.throwWithStackTrace(SignUpEmailInUseFailure(error), stackTrace);
        case 'invalid-email':
          Error.throwWithStackTrace(
            SignUpInvalidEmailFailure(error),
            stackTrace,
          );
        case 'operation-not-allowed':
          Error.throwWithStackTrace(
            SignUpOperationNotAllowedFailure(error),
            stackTrace,
          );
        case 'weak-password':
          Error.throwWithStackTrace(
            SignUpWeakPasswordFailure(error),
            stackTrace,
          );
        default:
          Error.throwWithStackTrace(SignUpFailure(error), stackTrace);
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(SignUpFailure(error), stackTrace);
    }
  }

  /// Sends a password reset link to the provided [email].
  ///
  /// Throws:
  /// - [ResetPasswordInvalidEmailFailure] when [email] is invalid.
  /// - [ResetPasswordUserNotFoundFailure] when user with [email] is not found.
  /// - [ResetPasswordFailure] when unknown error occurs.
  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (error, stackTrace) {
      switch (error.code) {
        case 'invalid-email':
          Error.throwWithStackTrace(
            ResetPasswordInvalidEmailFailure(error),
            stackTrace,
          );
        case 'user-not-found':
          Error.throwWithStackTrace(
            ResetPasswordUserNotFoundFailure(error),
            stackTrace,
          );
        default:
          Error.throwWithStackTrace(ResetPasswordFailure(error), stackTrace);
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ResetPasswordFailure(error), stackTrace);
    }
  }

  /// Starts the Sign In with Apple Flow.
  ///
  /// Throws a [LogInWithAppleFailure] if an exception occurs.
  @override
  Future<void> logInWithApple() async {
    try {
      final appleIdCredential = await _getAppleCredentials(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = firebase_auth.OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleIdCredential.identityToken,
        accessToken: appleIdCredential.authorizationCode,
      );

      final user =
          await _firebaseAuth.currentUser?.linkWithCredential(credential);

      if (user != null) {
        _userController.add(user.toUser);
      } else {
        final userCredential = await _lock.run(
          () => _firebaseAuth.signInWithCredential(credential),
        );
        _userController.add(userCredential.toUser);
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(LogInWithAppleFailure(error), stackTrace);
    }
  }

  /// Starts the Sign In with Google Flow.
  ///
  /// Throws a [LogInWithGoogleCanceled] if the flow is canceled by the user.
  /// Throws a [LogInWithGoogleFailure] if an exception occurs.
  @override
  Future<void> logInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw LogInWithGoogleCanceled(
          Exception('Sign in with Google canceled'),
        );
      }
      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      firebase_auth.UserCredential? userCredential;
      try {
        userCredential =
            await _firebaseAuth.currentUser?.linkWithCredential(credential);
      } catch (e) {
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      if (userCredential != null) {
        _userController.add(userCredential.toUser);
      } else {
        final userCredential = await _lock.run(
          () => _firebaseAuth.signInWithCredential(credential),
        );
        _userController.add(userCredential.toUser);
      }
    } on LogInWithGoogleCanceled {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(LogInWithGoogleFailure(error), stackTrace);
    }
  }

  /// Signs in with the provided [email] and [password].
  ///
  /// Throws a [LogInWithEmailAndPasswordFailure] if an exception occurs.
  @override
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      firebase_auth.UserCredential? user;
      try {
        user = await _firebaseAuth.currentUser?.linkWithCredential(credential);
      } catch (e) {
        user = await _firebaseAuth.signInWithCredential(credential);
      }
      if (user != null) {
        _userController.add(user.toUser);
      } else {
        final userCredential = await _lock.run(
          () => _firebaseAuth.signInWithCredential(credential),
        );
        _userController.add(userCredential.toUser);
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LogInWithEmailAndPasswordFailure(error),
        stackTrace,
      );
    }
  }

  /// Signs in anonymously.
  ///
  /// Throws a [AnonymousSignInFailure] if an exception occurs.
  Future<firebase_auth.User> anonymouslySignIn(
    firebase_auth.User? firebaseUser,
  ) async {
    try {
      if (firebaseUser == null) {
        final userCredential = await _lock.run(
          _firebaseAuth.signInAnonymously,
        );

        return userCredential.user!;
      } else {
        return firebaseUser;
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AnonymousSignInFailure(error),
        stackTrace,
      );
    }
  }

  /// Signs out the current user which will emit
  /// [User.unauthenticated] from the [user] Stream.
  ///
  /// Throws a [LogOutFailure] if an exception occurs.
  @override
  Future<void> logOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(LogOutFailure(error), stackTrace);
    }
  }

  @override
  void dispose() {
    _firebaseUserSubscription?.cancel();
    _userController.close();
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _firebaseAuth.currentUser?.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _reauthenticateAndDelete();
      }
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(DeleteAccountFailure(e), stackTrace);
    }
  }

  Future<void> _reauthenticateAndDelete() async {
    try {
      final providerData = _firebaseAuth.currentUser?.providerData.first;

      if (firebase_auth.AppleAuthProvider().providerId ==
          providerData!.providerId) {
        await _firebaseAuth.currentUser!
            .reauthenticateWithProvider(firebase_auth.AppleAuthProvider());
      } else if (firebase_auth.GoogleAuthProvider().providerId ==
          providerData.providerId) {
        await _firebaseAuth.currentUser!
            .reauthenticateWithProvider(firebase_auth.GoogleAuthProvider());
      }

      await _firebaseAuth.currentUser?.delete();
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(DeleteAccountFailure(e), stackTrace);
    }
  }

  @override
  void onGoogleUserAuthorized() {
    // TODO(jshewmak): implement onGoogleUserAuthorized
    throw UnimplementedError();
  }
}

extension on firebase_auth.User {
  User toUser() {
    return User(
      id: uid,
      email: email,
      name: displayName,
      photo: photoURL,
      isAnonymous: email == null || email == '',
    );
  }
}

extension on firebase_auth.UserCredential {
  User get toUser {
    if (user == null) return User.unauthenticated;
    return user!.toUser();
  }
}
