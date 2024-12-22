// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();
}

class LoginEmailChanged extends LoginEvent {
  const LoginEmailChanged(this.email);

  final String email;

  @override
  List<Object> get props => [email];
}

class LoginPasswordChanged extends LoginEvent {
  const LoginPasswordChanged(this.password);

  final String password;

  @override
  List<Object> get props => [password];
}

class LoginCredentialsSubmitted extends LoginEvent with AnalyticsEventMixin {
  const LoginCredentialsSubmitted();

  @override
  AnalyticsEvent get event => const AnalyticsEvent('LoginCredentialsSubmitted');
}

class LoginGoogleSubmitted extends LoginEvent with AnalyticsEventMixin {
  const LoginGoogleSubmitted();

  @override
  AnalyticsEvent get event => const AnalyticsEvent('LoginGoogleSubmitted');
}

class GoogleSignInWebInitialized extends LoginEvent with AnalyticsEventMixin {
  const GoogleSignInWebInitialized();

  @override
  AnalyticsEvent get event => const AnalyticsEvent(
        'GoogleSignInWebInitialized',
      );
}

class LoginAppleSubmitted extends LoginEvent with AnalyticsEventMixin {
  const LoginAppleSubmitted();

  @override
  AnalyticsEvent get event => const AnalyticsEvent('LoginAppleSubmitted');
}
