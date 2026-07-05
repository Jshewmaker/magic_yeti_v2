import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:user_repository/user_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    required UserRepository userRepository,
    required User userProfile,
  })  : _firebaseDatabaseRepository = firebaseDatabaseRepository,
        _userRepository = userRepository,
        super(ProfileState(user: userProfile)) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileEditingToggled>(_onEditingToggled);
    on<ProfileUsernameChanged>(_onUsernameChanged);
    on<ProfileFirstNameChanged>(_onFirstNameChanged);
    on<ProfileLastNameChanged>(_onLastNameChanged);
    on<ProfileBioChanged>(_onBioChanged);
    on<ProfileSubmitted>(_onSubmitted);
    on<ProfilePinChanged>(_onPinChanged);
    on<ProfilePinSubmitted>(_onPinSubmitted);
    on<ProfileDeleted>(_onDeleteProfile);
  }

  final FirebaseDatabaseRepository _firebaseDatabaseRepository;
  final UserRepository _userRepository;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile =
          await _firebaseDatabaseRepository.getUserProfileOnce(event.userId);
      if (profile == null) {
        // A missing profile doc is a failure, not an empty success — the
        // page would otherwise render a silent blank with no retry.
        emit(state.copyWith(status: ProfileStatus.failure));
        return;
      }
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          profile: profile,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ProfileStatus.failure));
    }
  }

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
    final loaded = state.profile;
    if (loaded == null) return;

    // A present-but-invalid username (e.g. cleared to empty) must never
    // reach updateUserProfile: saving `username: ''` would flip
    // UserProfileModel.isComplete false, bouncing the user back into
    // onboarding on the next auth event.
    if (state.username != null && !Formz.validate([state.username!])) {
      emit(state.copyWith(status: ProfileStatus.failure));
      return;
    }

    emit(state.copyWith(status: ProfileStatus.loading));

    try {
      // Build the save model FROM the loaded profile via copyWith so
      // fields the profile form never touches (pin/hasPin/friendCode/
      // onboardingComplete/imageUrl) are carried over automatically.
      // Constructing a fresh UserProfileModel(...) here instead would
      // silently drop those fields on save (the Fix-2-class regression
      // this bloc must never reintroduce).
      final updatedProfile = loaded.copyWith(
        username: state.username?.value ?? loaded.username,
        firstName: state.firstName ?? loaded.firstName,
        lastName: state.lastName ?? loaded.lastName,
        bio: state.bio ?? loaded.bio,
      );

      await _firebaseDatabaseRepository.updateUserProfile(
        state.user.id,
        updatedProfile,
      );
      emit(
        state.copyWith(
          status: ProfileStatus.success,
          isEditing: false,
          profile: updatedProfile,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ProfileStatus.failure));
    }
  }

  void _onPinChanged(
    ProfilePinChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(pin: Pin.dirty(event.pin)));
  }

  Future<void> _onPinSubmitted(
    ProfilePinSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    if (!state.pin.isValid) return;

    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      // Decision #5: changing the PIN from the profile page does not
      // require re-entering the old PIN first.
      await _firebaseDatabaseRepository.setPin(state.user.id, state.pin.value);
      emit(state.copyWith(status: ProfileStatus.pinSaved));
    } catch (_) {
      emit(state.copyWith(status: ProfileStatus.failure));
    }
  }

  Future<void> _onDeleteProfile(
    ProfileDeleted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      // Account deletion itself is client-driven here; the Firestore-side
      // cleanup of friends/requests/blocks tied to this account now runs
      // server-side (Task 1's trigger), so no client-side fan-out cleanup
      // is needed before/after this call.
      await _userRepository.deleteAccount();
      emit(state.copyWith(status: ProfileStatus.success));
    } catch (_) {
      emit(state.copyWith(status: ProfileStatus.failure));
    }
  }
}
