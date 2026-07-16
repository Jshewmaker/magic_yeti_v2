part of 'onboarding_bloc.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.currentStep = 0,
    this.username = const Username.pure(),
    this.pin = const Pin.pure(),
    this.bio = '',
    this.hasExistingPin = false,
    this.status = FormzSubmissionStatus.initial,
  });

  final int currentStep;
  final Username username;
  final Pin pin;
  final String bio;
  final bool hasExistingPin;
  final FormzSubmissionStatus status;

  /// Per-step validation.
  /// Step 0: username must be valid
  /// Step 1: PIN must be valid OR an existing PIN is already set
  /// Step 2: always valid (optional bio field)
  bool get isStepValid {
    switch (currentStep) {
      case 0:
        return username.isValid;
      case 1:
        return pin.isValid || hasExistingPin;
      case 2:
        return true;
      default:
        return false;
    }
  }

  OnboardingState copyWith({
    int? currentStep,
    Username? username,
    Pin? pin,
    String? bio,
    bool? hasExistingPin,
    FormzSubmissionStatus? status,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      username: username ?? this.username,
      pin: pin ?? this.pin,
      bio: bio ?? this.bio,
      hasExistingPin: hasExistingPin ?? this.hasExistingPin,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        username,
        pin,
        bio,
        hasExistingPin,
        status,
      ];
}
