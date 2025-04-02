part of 'friend_list_bloc.dart';

/// Events for the FriendsBloc.
/// Defines the actions that can be performed on the friends list.
///
/// Key events:
/// - LoadFriends: Triggered to load the friends list
/// - RemoveFriend: Triggered to remove a friend

sealed class FriendEvent extends Equatable {
  const FriendEvent();

  @override
  List<Object> get props => [];
}

class LoadFriends extends FriendEvent {
  const LoadFriends(this.userId);
  final String userId;

  @override
  List<Object> get props => [userId];
}

class RemoveFriend extends FriendEvent {
  const RemoveFriend(this.userId, this.friendId);
  final String userId;
  final String friendId;

  @override
  List<Object> get props => [userId, friendId];
}
