import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:image_picker/image_picker.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    UserProfileModel? existingProfile,
  })  : _firebaseDatabaseRepository = firebaseDatabaseRepository,
        super(
          OnboardingState(
            username: existingProfile?.username != null &&
                    existingProfile!.username!.isNotEmpty
                ? Username.dirty(existingProfile.username!)
                : const Username.pure(),
            firstName: existingProfile?.firstName ?? '',
            lastName: existingProfile?.lastName ?? '',
            bio: existingProfile?.bio ?? '',
            hasExistingPin: (existingProfile?.hasPin ?? false) ||
                (existingProfile?.pin?.isNotEmpty ?? false),
            existingImageUrl: existingProfile?.imageUrl,
          ),
        ) {
    on<OnboardingUsernameChanged>(_onUsernameChanged);
    on<OnboardingPinChanged>(_onPinChanged);
    on<OnboardingFirstNameChanged>(_onFirstNameChanged);
    on<OnboardingLastNameChanged>(_onLastNameChanged);
    on<OnboardingBioChanged>(_onBioChanged);
    on<OnboardingStepNext>(_onStepNext);
    on<OnboardingStepBack>(_onStepBack);
    on<OnboardingProfileImagePicked>(_onProfileImagePicked);
    on<OnboardingSubmitted>(_onSubmitted);
  }

  final FirebaseDatabaseRepository _firebaseDatabaseRepository;

  void _onUsernameChanged(
    OnboardingUsernameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(username: Username.dirty(event.username)));
  }

  void _onPinChanged(
    OnboardingPinChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(pin: Pin.dirty(event.pin)));
  }

  void _onFirstNameChanged(
    OnboardingFirstNameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(firstName: event.firstName));
  }

  void _onLastNameChanged(
    OnboardingLastNameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(lastName: event.lastName));
  }

  void _onBioChanged(
    OnboardingBioChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(bio: event.bio));
  }

  void _onStepNext(
    OnboardingStepNext event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.isStepValid && state.currentStep < 3) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void _onStepBack(
    OnboardingStepBack event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void _onProfileImagePicked(
    OnboardingProfileImagePicked event,
    Emitter<OnboardingState> emit,
  ) {
    emit(
      state.copyWith(
        profileImagePath: () =>
            event.imagePath.isEmpty ? null : event.imagePath,
      ),
    );
  }

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
    try {
      // Upload profile picture if selected
      String? imageUrl = state.existingImageUrl;
      if (state.profileImagePath != null) {
        final file = XFile(state.profileImagePath!);
        final bytes = await file.readAsBytes();
        imageUrl = await _firebaseDatabaseRepository.uploadProfilePicture(
          event.userId,
          bytes,
        );
      }

      // Generate friend code if not already present
      final existingProfile = await _firebaseDatabaseRepository
          .getUserProfileOnce(event.userId);
      final friendCode = existingProfile?.friendCode ??
          await _firebaseDatabaseRepository.generateUniqueFriendCode();

      final hasNewPin = state.pin.value.isNotEmpty;

      await _firebaseDatabaseRepository.updateUserProfile(
        event.userId,
        UserProfileModel(
          id: event.userId,
          email: existingProfile?.email,
          username: state.username.value,
          firstName: state.firstName,
          lastName: state.lastName,
          bio: state.bio,
          imageUrl: imageUrl,
          friendCode: friendCode,
          hasPin: hasNewPin || state.hasExistingPin,
          onboardingComplete: true,
        ),
      );

      // Persist a newly entered PIN as a salted hash in the private
      // credentials subcollection (never on the profile document).
      if (hasNewPin) {
        await _firebaseDatabaseRepository.setPin(
          event.userId,
          state.pin.value,
        );
      }

      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on Exception catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }
}
