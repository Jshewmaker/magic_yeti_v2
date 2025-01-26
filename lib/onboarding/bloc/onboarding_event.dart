part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object> get props => [];
}

class OnboardingUsernameChanged extends OnboardingEvent {
  const OnboardingUsernameChanged(this.username);

  final String username;

  @override
  List<Object> get props => [username];
}

class OnboardingFirstNameChanged extends OnboardingEvent {
  const OnboardingFirstNameChanged(this.firstName);

  final String firstName;

  @override
  List<Object> get props => [firstName];
}

class OnboardingLastNameChanged extends OnboardingEvent {
  const OnboardingLastNameChanged(this.lastName);

  final String lastName;

  @override
  List<Object> get props => [lastName];
}

class OnboardingBioChanged extends OnboardingEvent {
  const OnboardingBioChanged(this.bio);

  final String bio;

  @override
  List<Object> get props => [bio];
}

class OnboardingSubmitted extends OnboardingEvent {
  const OnboardingSubmitted({
    this.username,
    this.firstName,
    this.lastName,
    this.bio,
  });

  final Username? username;
  final String? firstName;
  final String? lastName;
  final String? bio;

  @override
  List<Object> get props => [];
}
