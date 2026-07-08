part of 'profile_bloc.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  success,
  failure,
  pinSaved,
  usernameInvalid,
}

class ProfileState extends Equatable {
  const ProfileState({
    required this.user,
    this.status = ProfileStatus.initial,
    this.profile,
    this.isEditing = false,
    this.username,
    this.bio,
    this.isValid = false,
    this.pin = const Pin.pure(),
  });

  final ProfileStatus status;

  /// The authenticated user; kept only for id/email display. Profile
  /// fields (username/name/bio/pin/friendCode) live on [profile].
  final User user;

  /// The full profile document, loaded via `getUserProfileOnce`. Null
  /// until the initial load completes.
  final UserProfileModel? profile;
  final bool isEditing;
  final Username? username;
  final String? bio;
  final bool isValid;
  final Pin pin;

  ProfileState copyWith({
    ProfileStatus? status,
    User? user,
    UserProfileModel? profile,
    bool? isEditing,
    Username? username,
    String? bio,
    bool? isValid,
    Pin? pin,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isEditing: isEditing ?? this.isEditing,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      isValid: isValid ?? this.isValid,
      pin: pin ?? this.pin,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        profile,
        isEditing,
        username,
        bio,
        isValid,
        pin,
      ];
}
