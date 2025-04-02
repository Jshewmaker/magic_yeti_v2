part of 'friend_request_bloc.dart';

/// Defines the states for the FriendRequestBloc.
///
/// States:
/// - FriendRequestLoading: Indicates loading state.
/// - FriendRequestLoaded: Indicates successful loading of friend requests.
/// - FriendRequestError: Indicates an error occurred while loading requests.

abstract class FriendRequestState extends Equatable {
  const FriendRequestState();

  @override
  List<Object> get props => [];
}

class FriendRequestLoading extends FriendRequestState {}

class FriendRequestLoaded extends FriendRequestState {
  const FriendRequestLoaded(this.requests);
  final List<FriendRequestModel> requests;

  @override
  List<Object> get props => [requests];
}

class FriendRequestError extends FriendRequestState {
  const FriendRequestError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
