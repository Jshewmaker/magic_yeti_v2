part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class OnboardingUsernameChanged extends OnboardingEvent {
  const OnboardingUsernameChanged(this.username);
  final String username;

  @override
  List<Object?> get props => [username];
}

class OnboardingPinChanged extends OnboardingEvent {
  const OnboardingPinChanged(this.pin);
  final String pin;

  @override
  List<Object?> get props => [pin];
}

class OnboardingBioChanged extends OnboardingEvent {
  const OnboardingBioChanged(this.bio);
  final String bio;

  @override
  List<Object?> get props => [bio];
}

class OnboardingStepNext extends OnboardingEvent {
  const OnboardingStepNext();
}

class OnboardingStepBack extends OnboardingEvent {
  const OnboardingStepBack();
}

class OnboardingProfileImagePicked extends OnboardingEvent {
  const OnboardingProfileImagePicked(this.imagePath);
  final String imagePath;

  @override
  List<Object?> get props => [imagePath];
}

class OnboardingSubmitted extends OnboardingEvent {
  const OnboardingSubmitted(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}
