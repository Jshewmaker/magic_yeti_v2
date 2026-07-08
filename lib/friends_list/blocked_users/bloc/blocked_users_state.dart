part of 'blocked_users_bloc.dart';

/// States for the BlockedUsersBloc.
///
/// Key states:
/// - BlockedUsersLoading: Indicates loading state
/// - BlockedUsersLoaded: Indicates blocked users are successfully loaded
/// - BlockedUsersError: Indicates an error occurred

abstract class BlockedUsersState extends Equatable {
  const BlockedUsersState();

  @override
  List<Object> get props => [];
}

class BlockedUsersLoading extends BlockedUsersState {}

class BlockedUsersLoaded extends BlockedUsersState {
  const BlockedUsersLoaded(this.blockedUsers);
  final List<BlockedUserModel> blockedUsers;

  @override
  List<Object> get props => [blockedUsers];
}

class BlockedUsersError extends BlockedUsersState {
  const BlockedUsersError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
