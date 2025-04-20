part of 'friend_request_bloc.dart';

/// Defines the events for the FriendRequestBloc.
///
/// Events:
/// - LoadFriendRequests: Triggered to load friend requests from Firestore.
/// - AcceptFriendRequest: Triggered to accept a friend request.
/// - DeclineFriendRequest: Triggered to decline a friend request.

sealed class FriendRequestEvent extends Equatable {
  const FriendRequestEvent();

  @override
  List<Object> get props => [];
}

class LoadFriendRequests extends FriendRequestEvent {
  const LoadFriendRequests(this.userId);
  final String userId;

  @override
  List<Object> get props => [userId];
}

/// Triggered to accept a friend request.
///
/// [request] is the friend request to accept.
/// [userId] is the ID of the user accepting the request.
class AcceptFriendRequest extends FriendRequestEvent {
  const AcceptFriendRequest(this.request, this.userId);
  final FriendRequestModel request;
  final String userId;

  @override
  List<Object> get props => [request, userId];
}

class DeclineFriendRequest extends FriendRequestEvent {
  const DeclineFriendRequest(this.request);
  final FriendRequestModel request;

  @override
  List<Object> get props => [request];
}
