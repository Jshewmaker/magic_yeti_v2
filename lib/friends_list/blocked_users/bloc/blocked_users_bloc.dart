import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';

part 'blocked_users_event.dart';
part 'blocked_users_state.dart';

/// Bloc implementation for managing the user's blocked-users list.
///
/// Key features:
/// - Subscribes to the repository's blocked-users stream
/// - Unblocks a previously blocked user
///
/// @dependencies
/// - FirebaseDatabaseRepository: For interacting with Firestore
/// - Flutter Bloc: For state management
class BlockedUsersBloc extends Bloc<BlockedUsersEvent, BlockedUsersState> {
  BlockedUsersBloc({required this.repository})
      : super(BlockedUsersLoading()) {
    on<LoadBlockedUsers>(_onLoadBlockedUsers);
    on<UnblockUser>(_onUnblockUser);
  }

  final FirebaseDatabaseRepository repository;

  Future<void> _onLoadBlockedUsers(
    LoadBlockedUsers event,
    Emitter<BlockedUsersState> emit,
  ) async {
    emit(BlockedUsersLoading());
    await emit.forEach<List<BlockedUserModel>>(
      repository.getBlockedUsers(event.userId),
      onData: BlockedUsersLoaded.new,
      onError: (error, stackTrace) =>
          BlockedUsersError('Failed to load blocked users: $error'),
    );
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<BlockedUsersState> emit,
  ) async {
    try {
      await repository.unblockUser(
        currentUserId: event.userId,
        targetUserId: event.targetUserId,
      );
    } on Exception catch (e) {
      emit(BlockedUsersError('Failed to unblock user: $e'));
    }
  }
}
