// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'dart:async';

import 'package:authentication_client/authentication_client.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:rxdart/rxdart.dart';

/// {@template user_repository}
/// Repository which manages the user domain.
/// {@endtemplate}
class UserRepository {
  /// {@macro user_repository}
  UserRepository({
    required AuthenticationClient authenticationClient,
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
  })  : _authenticationClient = authenticationClient,
        _firebaseDatabaseRepository = firebaseDatabaseRepository;

  final AuthenticationClient _authenticationClient;
  final FirebaseDatabaseRepository _firebaseDatabaseRepository;
  final _userController = PublishSubject<UserProfileModel>();

  /// Stream of [User] which will emit the current user when
  /// the authentication state changes or when the user profile is updated.
  ///
  /// Emits [User.unauthenticated] if the user is not authenticated.
  Stream<UserProfileModel> get user => Rx.merge([
        _authenticationClient.user.switchMap((user) {
          if (user == User.unauthenticated || user.id.isEmpty) {
            return Stream.value(UserProfileModel.empty);
          }
          return _firebaseDatabaseRepository
              .getUserProfile(user.id)
              .onErrorResume(
                (error, stackTrace) => Stream.value(
                  UserProfileModel(
                    id: user.id,
                    email: user.email ?? '',
                    username: user.name?.split(' ').first ?? '',
                    firstName: user.name?.split(' ').first ?? '',
                    lastName: user.name?.split(' ').last ?? '',
                    bio: '',
                    imageUrl: user.photo ?? '',
                    isNewUser: true,
                    isAnonymous: user.isAnonymous,
                  ),
                ),
              );
        }),
        _userController.stream,
      ]);

  /// Creates a new user with the provided [email] and [password].
  ///
  /// Throws a [SignUpFailure] if an exception occurs.
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _authenticationClient.signUp(
        email: email,
        password: password,
      );
    } on SignUpFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(SignUpFailure(error), stackTrace);
    }
  }

  /// Sends a password reset link to the provided [email].
  ///
  /// Throws a [ResetPasswordFailure] if an exception occurs.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _authenticationClient.sendPasswordResetEmail(email: email);
    } on ResetPasswordFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ResetPasswordFailure(error), stackTrace);
    }
  }

  /// Starts the Sign In with Apple Flow.
  ///
  /// Throws a [LogInWithAppleFailure] if an exception occurs.
  Future<void> logInWithApple() async {
    try {
      await _authenticationClient.logInWithApple();
    } on LogInWithAppleFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(LogInWithAppleFailure(error), stackTrace);
    }
  }

  /// Starts the Sign In with Google Flow.
  ///
  /// Throws a [LogInWithGoogleCanceled] if the flow is canceled by the user.
  /// Throws a [LogInWithEmailAndPasswordFailure] if an exception occurs.
  Future<void> logInWithGoogle() async {
    try {
      await _authenticationClient.logInWithGoogle();
    } on LogInWithGoogleFailure {
      rethrow;
    } on LogInWithGoogleCanceled {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(LogInWithGoogleFailure(error), stackTrace);
    }
  }

  /// Listens to changes in the current user and its authorization to access
  /// the provided scopes.
  void onGoogleUserAuthorized() {
    _authenticationClient.onGoogleUserAuthorized();
  }

  /// Signs in with the provided [email] and [password].
  ///
  /// Throws a [LogInWithEmailAndPasswordFailure] if an exception occurs.
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _authenticationClient.logInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on LogInWithEmailAndPasswordFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LogInWithEmailAndPasswordFailure(error),
        stackTrace,
      );
    }
  }

  /// Signs out the current user which will emit
  /// [User.unauthenticated] from the [user] Stream.
  ///
  /// Throws a [LogOutFailure] if an exception occurs.
  Future<void> logOut() async {
    try {
      await _authenticationClient.logOut();
    } on LogOutFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(LogOutFailure(error), stackTrace);
    }
  }

  /// Deletes the account of the current user which will emit
  /// [User.unauthenticated] from the [user] Stream.
  ///
  /// Throws a [DeleteAccountFailure] if an exception occurs.
  Future<void> deleteAccount() async {
    try {
      await _authenticationClient.deleteAccount();
    } on DeleteAccountFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(DeleteAccountFailure(error), stackTrace);
    }
  }
}
