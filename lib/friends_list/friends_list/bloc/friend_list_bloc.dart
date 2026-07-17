import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';

part 'friend_list_event.dart';
part 'friend_list_state.dart';

/// Bloc implementation for managing the user's friends list.
/// It handles streaming the list of friends, removing friends, and blocking.
///
/// Key features:
/// - Subscribes to the repository's friends stream
/// - Removes friends with confirmation
/// - Blocks a friend
///
/// @dependencies
/// - FirebaseDatabaseRepository: For interacting with Firestore
/// - Flutter Bloc: For state management
///
/// @notes
/// - Implements error handling for network issues
class FriendBloc extends Bloc<FriendEvent, FriendState> {
  FriendBloc({required this.repository}) : super(FriendsLoading()) {
    // restartable: see MatchHistoryBloc — emit.forEach never completes on its
    // own, so a re-dispatch must cancel the previous subscription.
    on<LoadFriends>(_onLoadFriends, transformer: restartable());
    on<RemoveFriend>(_onRemoveFriend);
    on<BlockFriend>(_onBlockFriend);
  }

  final FirebaseDatabaseRepository repository;

  Future<void> _onLoadFriends(
    LoadFriends event,
    Emitter<FriendState> emit,
  ) async {
    // An empty userId means "no signed-in user": clear and stop listening.
    if (event.userId.isEmpty) {
      emit(const FriendsLoaded([]));
      return;
    }

    emit(FriendsLoading());
    await emit.forEach<List<FriendModel>>(
      repository.watchFriends(event.userId),
      onData: FriendsLoaded.new,
      onError: (error, _) => FriendsError('Failed to load friends: $error'),
    );
  }

  Future<void> _onRemoveFriend(
    RemoveFriend event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await repository.removeFriend(event.userId, event.friendId);
      // No emit: removeFriend deletes both friendList edges, so the stream
      // re-emits without them.
    } catch (e) {
      emit(FriendsError('Failed to remove friend: $e'));
    }
  }

  Future<void> _onBlockFriend(
    BlockFriend event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await repository.blockUser(
        currentUserId: event.userId,
        target: event.target,
      );
      // No emit: blockUser deletes both friendList edges in its batch, so the
      // stream re-emits without them.
    } on Exception catch (e) {
      emit(FriendsError('Failed to block friend: $e'));
    }
  }
}
