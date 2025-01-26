import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:form_inputs/form_inputs.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    required UserProfileModel userProfile,
  })  : _firebaseDatabaseRepository = firebaseDatabaseRepository,
        _userProfile = userProfile,
        super(const OnboardingState()) {
    on<OnboardingUsernameChanged>(_onUsernameChanged);
    on<OnboardingFirstNameChanged>(_onFirstNameChanged);
    on<OnboardingLastNameChanged>(_onLastNameChanged);
    on<OnboardingBioChanged>(_onBioChanged);
    on<OnboardingSubmitted>(_onSubmitted);
  }

  final FirebaseDatabaseRepository _firebaseDatabaseRepository;
  final UserProfileModel _userProfile;

  void _onUsernameChanged(
    OnboardingUsernameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    final username = Username.dirty(event.username);
    emit(
      state.copyWith(
        username: username,
        isValid: Formz.validate([username]),
      ),
    );
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

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    if (!state.isValid) return;
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
    try {
      await _firebaseDatabaseRepository.updateUserProfile(
        _userProfile.id,
        _userProfile.copyWith(
          username: state.username.value,
          firstName: state.firstName,
          lastName: state.lastName,
          bio: state.bio,
          isNewUser: false,
        ),
      );
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }
}
