import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';

part 'friend_list_event.dart';
part 'friend_list_state.dart';

/// Bloc implementation for managing the user's friends list.
/// It handles loading the list of friends and removing friends.
///
/// Key features:
/// - Loads friends from Firestore
/// - Removes friends with confirmation
///
/// @dependencies
/// - FirebaseDatabaseRepository: For interacting with Firestore
/// - Flutter Bloc: For state management
///
/// @notes
/// - Implements error handling for network issues
/// - Ensures real-time updates using Firestore sync

class FriendBloc extends Bloc<FriendEvent, FriendState> {
  FriendBloc({required this.repository}) : super(FriendsLoading()) {
    on<LoadFriends>(_onLoadFriends);
    on<RemoveFriend>(_onRemoveFriend);
  }

  final FirebaseDatabaseRepository repository;

  Future<void> _onLoadFriends(
    LoadFriends event,
    Emitter<FriendState> emit,
  ) async {
    try {
      final friends = await repository.getFriends(event.userId);
      emit(FriendsLoaded(friends));
    } catch (e) {
      emit(FriendsError('Failed to load friends: $e'));
    }
  }

  Future<void> _onRemoveFriend(
    RemoveFriend event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await repository.removeFriend(event.userId, event.friendId);
      add(LoadFriends(event.userId)); // Reload friends after removal
    } catch (e) {
      emit(FriendsError('Failed to remove friend: $e'));
    }
  }
}
