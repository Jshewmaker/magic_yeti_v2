// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

part of 'reset_password_bloc.dart';

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.email = const Email.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.valid = false,
  });

  final Email email;
  final FormzSubmissionStatus status;
  final bool valid;

  @override
  List<Object> get props => [email, status, valid];

  ResetPasswordState copyWith({
    Email? email,
    FormzSubmissionStatus? status,
    bool? valid,
  }) {
    return ResetPasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
      valid: valid ?? this.valid,
    );
  }
}
