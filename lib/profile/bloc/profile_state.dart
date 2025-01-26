part of 'profile_bloc.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    required this.userProfile,
    this.status = ProfileStatus.initial,
    this.isEditing = false,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.bio,
    this.isValid = false,
  });

  final ProfileStatus status;
  final bool isEditing;
  final Username? username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? bio;
  final bool isValid;
  final UserProfileModel userProfile;

  ProfileState copyWith({
    ProfileStatus? status,
    bool? isEditing,
    Username? username,
    String? firstName,
    String? lastName,
    String? email,
    String? bio,
    bool? isValid,
    UserProfileModel? userProfile,
  }) {
    return ProfileState(
      status: status ?? this.status,
      isEditing: isEditing ?? this.isEditing,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      isValid: isValid ?? this.isValid,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isEditing,
        username,
        firstName,
        lastName,
        email,
        bio,
        isValid,
        userProfile,
      ];
}
