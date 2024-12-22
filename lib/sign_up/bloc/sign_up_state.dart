// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

part of 'sign_up_bloc.dart';

class SignUpState extends Equatable {
  const SignUpState({
    this.email = const Email.pure(),
    this.password = const SignUpPassword.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.valid = false,
  });

  final Email email;
  final SignUpPassword password;
  final FormzSubmissionStatus status;
  final bool valid;

  @override
  List<Object> get props => [email, password, status, valid];

  SignUpState copyWith({
    Email? email,
    SignUpPassword? password,
    FormzSubmissionStatus? status,
    bool? valid,
  }) {
    return SignUpState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      valid: valid ?? this.valid,
    );
  }
}
