part of 'onboarding_bloc.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.currentStep = 0,
    this.username = const Username.pure(),
    this.pin = const Pin.pure(),
    this.firstName = '',
    this.lastName = '',
    this.bio = '',
    this.profileImagePath,
    this.existingPinHash,
    this.existingImageUrl,
    this.status = FormzSubmissionStatus.initial,
  });

  final int currentStep;
  final Username username;
  final Pin pin;
  final String firstName;
  final String lastName;
  final String bio;
  final String? profileImagePath;
  final String? existingPinHash;
  final String? existingImageUrl;
  final FormzSubmissionStatus status;

  /// Per-step validation.
  /// Step 0: username must be valid
  /// Step 1: PIN must be valid OR existing PIN hash exists
  /// Steps 2-3: always valid (optional fields)
  bool get isStepValid {
    switch (currentStep) {
      case 0:
        return username.isValid;
      case 1:
        return pin.isValid || existingPinHash != null;
      case 2:
      case 3:
        return true;
      default:
        return false;
    }
  }

  OnboardingState copyWith({
    int? currentStep,
    Username? username,
    Pin? pin,
    String? firstName,
    String? lastName,
    String? bio,
    String? Function()? profileImagePath,
    String? Function()? existingPinHash,
    String? Function()? existingImageUrl,
    FormzSubmissionStatus? status,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      username: username ?? this.username,
      pin: pin ?? this.pin,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      profileImagePath: profileImagePath != null
          ? profileImagePath()
          : this.profileImagePath,
      existingPinHash: existingPinHash != null
          ? existingPinHash()
          : this.existingPinHash,
      existingImageUrl: existingImageUrl != null
          ? existingImageUrl()
          : this.existingImageUrl,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        username,
        pin,
        firstName,
        lastName,
        bio,
        profileImagePath,
        existingPinHash,
        existingImageUrl,
        status,
      ];
}
