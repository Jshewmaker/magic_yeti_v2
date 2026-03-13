part of 'onboarding_bloc.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.username = const Username.pure(),
    this.pin = const Pin.pure(),
    this.firstName = '',
    this.lastName = '',
    this.bio = '',
    this.status = FormzSubmissionStatus.initial,
    this.isValid = false,
  });

  final Username username;
  final Pin pin;
  final String firstName;
  final String lastName;
  final String bio;
  final FormzSubmissionStatus status;
  final bool isValid;

  OnboardingState copyWith({
    Username? username,
    Pin? pin,
    String? firstName,
    String? lastName,
    String? bio,
    FormzSubmissionStatus? status,
    bool? isValid,
  }) {
    return OnboardingState(
      username: username ?? this.username,
      pin: pin ?? this.pin,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object> get props => [
        username,
        pin,
        firstName,
        lastName,
        bio,
        status,
        isValid,
      ];
}
