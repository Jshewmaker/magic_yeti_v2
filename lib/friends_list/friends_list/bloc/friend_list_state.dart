part of 'friend_list_bloc.dart';

/// States for the FriendsBloc.
/// Represents the different states of the friends list.
///
/// Key states:
/// - FriendsLoading: Indicates loading state
/// - FriendsLoaded: Indicates friends are successfully loaded
/// - FriendsError: Indicates an error occurred

abstract class FriendState extends Equatable {
  const FriendState();

  @override
  List<Object> get props => [];
}

class FriendsLoading extends FriendState {}

class FriendsLoaded extends FriendState {
  const FriendsLoaded(this.friends);
  final List<FriendModel> friends;

  @override
  List<Object> get props => [friends];
}

class FriendsError extends FriendState {
  const FriendsError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
