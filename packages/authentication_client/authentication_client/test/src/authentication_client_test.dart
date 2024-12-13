// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

// ignore_for_file: prefer_const_constructors

import 'package:authentication_client/authentication_client.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

// AuthenticationClient is exported and can be implemented
class _FakeAuthenticationClient extends Fake implements AuthenticationClient {}

void main() {
  test('AuthenticationClient can be implemented', () {
    expect(_FakeAuthenticationClient.new, returnsNormally);
  });

  test('exports SignUpFailure', () {
    expect(() => SignUpFailure('oops'), returnsNormally);
  });

  test('exports SignUpEmailInUseFailure', () {
    expect(() => SignUpEmailInUseFailure('oops'), returnsNormally);
  });

  test('exports SignUpInvalidEmailFailure', () {
    expect(() => SignUpInvalidEmailFailure('oops'), returnsNormally);
  });

  test('exports SignUpOperationNotAllowedFailure', () {
    expect(() => SignUpOperationNotAllowedFailure('oops'), returnsNormally);
  });

  test('exports SignUpWeakPasswordFailure', () {
    expect(() => SignUpWeakPasswordFailure('oops'), returnsNormally);
  });

  test('exports ResetPasswordFailure', () {
    expect(() => ResetPasswordFailure('oops'), returnsNormally);
  });

  test('exports ResetPasswordInvalidEmailFailure', () {
    expect(() => ResetPasswordInvalidEmailFailure('oops'), returnsNormally);
  });

  test('exports ResetPasswordUserNotFoundFailure', () {
    expect(() => ResetPasswordUserNotFoundFailure('oops'), returnsNormally);
  });

  test('exports LogInWithEmailAndPasswordFailure', () {
    expect(() => LogInWithEmailAndPasswordFailure('oops'), returnsNormally);
  });

  test('exports LogInWithAppleFailure', () {
    expect(() => LogInWithAppleFailure('oops'), returnsNormally);
  });

  test('exports LogInWithGoogleFailure', () {
    expect(() => LogInWithGoogleFailure('oops'), returnsNormally);
  });

  test('exports LogInWithGoogleCanceled', () {
    expect(() => LogInWithGoogleCanceled('oops'), returnsNormally);
  });

  test('exports LogOutFailure', () {
    expect(() => LogOutFailure('oops'), returnsNormally);
  });

  test('exports DeleteAccountFailure', () {
    expect(() => DeleteAccountFailure('oops'), returnsNormally);
  });
}
