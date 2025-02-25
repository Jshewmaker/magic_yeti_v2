// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

part of 'sign_up_bloc.dart';

abstract class SignUpEvent extends Equatable {
  const SignUpEvent();

  @override
  List<Object> get props => [];
}

class SignUpEmailChanged extends SignUpEvent {
  const SignUpEmailChanged(this.email);

  final String email;

  @override
  List<Object> get props => [email];
}

class SignUpPasswordChanged extends SignUpEvent {
  const SignUpPasswordChanged(this.password);

  final String password;

  @override
  List<Object> get props => [password];
}

class SignUpSubmitted extends SignUpEvent {
  const SignUpSubmitted();
}

class SignUpGoogleSubmitted extends SignUpEvent {
  const SignUpGoogleSubmitted();
}

class SignUpAppleSubmitted extends SignUpEvent {
  const SignUpAppleSubmitted();
}
