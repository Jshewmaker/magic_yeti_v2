part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
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

class ProfileFirstNameChanged extends ProfileEvent {
  const ProfileFirstNameChanged(this.firstName);

  final String firstName;

  @override
  List<Object> get props => [firstName];
}

class ProfileLastNameChanged extends ProfileEvent {
  const ProfileLastNameChanged(this.lastName);

  final String lastName;

  @override
  List<Object> get props => [lastName];
}

class ProfileEmailChanged extends ProfileEvent {
  const ProfileEmailChanged(this.email);

  final String email;

  @override
  List<Object> get props => [email];
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

class ProfileDeleted extends ProfileEvent {
  const ProfileDeleted();
}
