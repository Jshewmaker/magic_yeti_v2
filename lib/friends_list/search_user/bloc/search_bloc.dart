import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'search_event.dart';
part 'search_state.dart';

/// This file implements the Bloc pattern for managing the state of user search functionality.
/// It handles the search logic, including loading, success, and error states using the FirebaseDatabaseRepository.
///
/// Key features:
/// - Event-driven architecture for search actions
/// - State management for search results and errors
/// - Integration with FirebaseDatabaseRepository for data fetching
///
/// @dependencies
/// - FirebaseDatabaseRepository: Used for querying user data
/// - Flutter Bloc: Used for managing state
///
/// @notes
/// - Implements robust error handling for network issues
/// - Ensures real-time updates using the repository

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required this.repository}) : super(SearchInitial()) {
    on<SearchUsers>(_onSearchUsers);
    on<AddFriendRequest>(_onAddFriendRequest);
  }
  final FirebaseDatabaseRepository repository;

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      final users = await repository.searchUsers(event.query);
      emit(SearchLoaded(users));
    } catch (e) {
      emit(SearchError('Failed to fetch users: $e'));
    }
  }

  Future<void> _onAddFriendRequest(
    AddFriendRequest event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      await repository.addFriendRequest(
        event.senderId,
        event.senderName,
        event.receiverId,
      );
      emit(const SearchLoaded([]));
    } catch (e) {
      emit(SearchError('Failed to add friend request: $e'));
    }
  }
}
