import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:form_inputs/form_inputs.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    required UserProfileModel userProfile,
  })  : _firebaseDatabaseRepository = firebaseDatabaseRepository,
        _userProfile = userProfile,
        super(ProfileState(userProfile: userProfile)) {
    on<ProfileEditingToggled>(_onEditingToggled);
    on<ProfileUsernameChanged>(_onUsernameChanged);
    on<ProfileFirstNameChanged>(_onFirstNameChanged);
    on<ProfileLastNameChanged>(_onLastNameChanged);
    on<ProfileEmailChanged>(_onEmailChanged);
    on<ProfileBioChanged>(_onBioChanged);
    on<ProfileSubmitted>(_onSubmitted);
  }

  final FirebaseDatabaseRepository _firebaseDatabaseRepository;
  final UserProfileModel _userProfile;

  void _onEditingToggled(
    ProfileEditingToggled event,
    Emitter<ProfileState> emit,
  ) {
    if (state.isEditing) {
      emit(state.copyWith(isEditing: false));
    } else {
      emit(state.copyWith(isEditing: true));
    }
  }

  void _onUsernameChanged(
    ProfileUsernameChanged event,
    Emitter<ProfileState> emit,
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
    ProfileFirstNameChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(firstName: event.firstName));
  }

  void _onLastNameChanged(
    ProfileLastNameChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(lastName: event.lastName));
  }

  void _onEmailChanged(
    ProfileEmailChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(email: event.email));
  }

  void _onBioChanged(
    ProfileBioChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(bio: event.bio));
  }

  Future<void> _onSubmitted(
    ProfileSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));

    try {
      final updatedProfile = _userProfile.copyWith(
        username: state.username?.value,
        firstName: state.firstName,
        lastName: state.lastName,
        email: state.email,
        bio: state.bio,
      );

      await _firebaseDatabaseRepository.updateUserProfile(
        _userProfile.id,
        updatedProfile,
      );
      emit(
        state.copyWith(
          status: ProfileStatus.success,
          isEditing: false,
          userProfile: updatedProfile,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ProfileStatus.failure));
    }
  }
}
