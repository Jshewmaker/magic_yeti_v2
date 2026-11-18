part of 'blocked_users_bloc.dart';

/// Events for the BlockedUsersBloc.
///
/// Key events:
/// - LoadBlockedUsers: Subscribes to the current user's blocked-users stream
/// - UnblockUser: Unblocks a previously blocked user

sealed class BlockedUsersEvent extends Equatable {
  const BlockedUsersEvent();

  @override
  List<Object> get props => [];
}

class LoadBlockedUsers extends BlockedUsersEvent {
  const LoadBlockedUsers(this.userId);
  final String userId;

  @override
  List<Object> get props => [userId];
}

class UnblockUser extends BlockedUsersEvent {
  const UnblockUser(this.userId, this.targetUserId);
  final String userId;
  final String targetUserId;

  @override
  List<Object> get props => [userId, targetUserId];
}
