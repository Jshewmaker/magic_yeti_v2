part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

/// Triggers the initial profile load via `getUserProfileOnce`.
class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested(this.userId);

  final String userId;

  @override
  List<Object> get props => [userId];
}

class ProfileEditingToggled extends ProfileEvent {
  const ProfileEditingToggled();
}

class ProfileUsernameChanged extends ProfileEvent {
  const ProfileUsernameChanged(this.username);

  final String username;

  @override
  List<Object> get props => [username];
}

class ProfileBioChanged extends ProfileEvent {
  const ProfileBioChanged(this.bio);

  final String bio;

  @override
  List<Object> get props => [bio];
}

class ProfileSubmitted extends ProfileEvent {
  const ProfileSubmitted();
}

/// New-PIN field changed on the profile page. Reuses the shared [Pin]
/// formz input.
class ProfilePinChanged extends ProfileEvent {
  const ProfilePinChanged(this.pin);

  final String pin;

  @override
  List<Object> get props => [pin];
}

/// Submits the entered PIN via `setPin`. Decision #5: no old-PIN prompt
/// is required to change the PIN from the profile page.
class ProfilePinSubmitted extends ProfileEvent {
  const ProfilePinSubmitted();
}

class ProfileDeleted extends ProfileEvent {
  const ProfileDeleted();
}
