// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'dart:async';

import 'package:authentication_client/authentication_client.dart';

/// {@template authentication_exception}
/// Exceptions from the authentication client.
/// {@endtemplate}
abstract class AuthenticationException implements Exception {
  /// {@macro authentication_exception}
  const AuthenticationException(this.error);

  /// The error which was caught.
  final Object error;
}

/// {@template sign_up_failure}
/// Thrown during the sign up process if a failure occurs.
/// {@endtemplate}
class SignUpFailure extends AuthenticationException {
  /// {@macro sign_up_failure}
  const SignUpFailure(super.error);
}

/// {@template sign_up_email_in_use_failure}
/// Thrown during the sign up process if the email is already in use.
/// {@endtemplate}
class SignUpEmailInUseFailure extends SignUpFailure {
  /// {@macro sign_up_email_in_use_failure}
  const SignUpEmailInUseFailure(super.error);
}

/// {@template sign_up_invalid_email_failure}
/// Thrown during the sign up process if the email is not valid.
/// {@endtemplate}
class SignUpInvalidEmailFailure extends SignUpFailure {
  /// {@macro sign_up_invalid_email_failure}
  const SignUpInvalidEmailFailure(super.error);
}

/// {@template sign_up_operation_not_allowed_failure}
/// Thrown during the sign up process if the operation is not allowed.
/// {@endtemplate}
class SignUpOperationNotAllowedFailure extends SignUpFailure {
  /// {@macro sign_up_operation_not_allowed_failure}
  const SignUpOperationNotAllowedFailure(super.error);
}

/// {@template sign_up_weak_password_failure}
/// Thrown during the sign up process if the password does not meet strength
/// requirements.
/// {@endtemplate}
class SignUpWeakPasswordFailure extends SignUpFailure {
  /// {@macro sign_up_weak_password_failure}
  const SignUpWeakPasswordFailure(super.error);
}

/// {@template reset_password_failure}
/// Thrown during the password reset process if a failure occurs.
/// {@endtemplate}
class ResetPasswordFailure extends AuthenticationException {
  /// {@macro reset_password_failure}
  const ResetPasswordFailure(super.error);
}

/// {@template reset_password_invalid_email_failure}
/// Thrown during the reset password process if the email is not valid.
/// {@endtemplate}
class ResetPasswordInvalidEmailFailure extends ResetPasswordFailure {
  /// {@macro reset_password_invalid_email_failure}
  const ResetPasswordInvalidEmailFailure(super.error);
}

/// {@template reset_password_user_not_found_failure}
/// Thrown during the reset password process if the email is not valid.
/// {@endtemplate}
class ResetPasswordUserNotFoundFailure extends ResetPasswordFailure {
  /// {@macro reset_password_user_not_found_failure}
  const ResetPasswordUserNotFoundFailure(super.error);
}

/// {@template log_in_with_email_and_password_failure}
/// Thrown during the login process if a failure occurs.
/// {@endtemplate}
class LogInWithEmailAndPasswordFailure extends AuthenticationException {
  /// {@macro log_in_with_email_and_password_failure}
  const LogInWithEmailAndPasswordFailure(super.error);
}

/// {@template log_in_with_apple_failure}
/// Thrown during the sign in with apple process if a failure occurs.
/// {@endtemplate}
class LogInWithAppleFailure extends AuthenticationException {
  /// {@macro log_in_with_apple_failure}
  const LogInWithAppleFailure(super.error);
}

/// {@template log_in_with_google_failure}
/// Thrown during the sign in with google process if a failure occurs.
/// {@endtemplate}
class LogInWithGoogleFailure extends AuthenticationException {
  /// {@macro log_in_with_google_failure}
  const LogInWithGoogleFailure(super.error);
}

/// {@template log_in_with_google_canceled}
/// Thrown during the sign in with google process if it's canceled.
/// {@endtemplate}
class LogInWithGoogleCanceled extends AuthenticationException {
  /// {@macro log_in_with_google_canceled}
  const LogInWithGoogleCanceled(super.error);
}

/// {@template log_out_failure}
/// Thrown during the logout process if a failure occurs.
/// {@endtemplate}
class LogOutFailure extends AuthenticationException {
  /// {@macro log_out_failure}
  const LogOutFailure(super.error);
}

/// {@template delete_account_failure}
/// Thrown during the delete account process if a failure occurs.
/// {@endtemplate}
class DeleteAccountFailure extends AuthenticationException {
  /// {@macro delete_account_failure}
  const DeleteAccountFailure(super.error);
}

/// A generic Authentication Client Interface.
abstract class AuthenticationClient {
  /// Stream of [User] which will emit the current user when
  /// the authentication state changes.
  ///
  /// Emits [User.unauthenticated] if the user is not authenticated.
  Stream<User> get user;

  /// Creates a new user with the provided [email] and [password].
  ///
  /// Throws a [SignUpFailure] if an exception occurs.
  Future<void> signUp({required String email, required String password});

  /// Sends a password reset link to the provided email
  ///
  /// Throws a [ResetPasswordFailure] if an exception occurs.
  Future<void> sendPasswordResetEmail({required String email});

  /// Starts the Sign In with Apple Flow.
  ///
  /// Throws a [LogInWithAppleFailure] if an exception occurs.
  Future<void> logInWithApple();

  /// Starts the Sign In with Google Flow.
  ///
  /// Throws a [LogInWithGoogleFailure] if an exception occurs.
  Future<void> logInWithGoogle();

  /// Listens to changes in the current user and its authorization to access
  /// the provided scopes.
  void onGoogleUserAuthorized();

  /// Signs in with the provided [email] and [password].
  ///
  /// Throws a [LogInWithEmailAndPasswordFailure] if an exception occurs.
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs out the current user which will emit
  /// [User.unauthenticated] from the [user] Stream.
  ///
  /// Throws a [LogOutFailure] if an exception occurs.
  Future<void> logOut();

  /// Deletes the account of the current user.
  Future<void> deleteAccount();

  /// Disposes any internal resources.
  /// Should be called when the instance is no longer needed.
  void dispose();
}
