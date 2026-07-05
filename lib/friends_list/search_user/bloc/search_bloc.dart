import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'search_event.dart';
part 'search_state.dart';

/// Bloc for managing the state of user search functionality.
///
/// Handles search logic, including loading, success, and error states
/// using the [FirebaseDatabaseRepository].

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required this.repository}) : super(SearchInitial()) {
    on<SearchByFriendCode>(_onSearchByFriendCode);
    on<AddFriendRequest>(_onAddFriendRequest);
  }
  final FirebaseDatabaseRepository repository;

  Future<void> _onSearchByFriendCode(
    SearchByFriendCode event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      final result = await repository.searchByFriendCode(event.friendCode);
      if (result.found && result.user != null) {
        emit(
          SearchLoaded(
            [result.user!],
            result.relationship ?? RelationshipStatus.none,
          ),
        );
      } else {
        emit(const SearchLoaded([], RelationshipStatus.none));
      }
      // ignore: avoid_catching_errors
    } on ArgumentError catch (e) {
      // The repository throws ArgumentError for a callable
      // `invalid-argument` response (e.g. an empty/blank code); surface it
      // the same as any other search failure instead of crashing the bloc.
      emit(SearchError('Failed to search by friend code: $e'));
    } on Exception catch (e) {
      emit(SearchError('Failed to search by friend code: $e'));
    }
  }

  Future<void> _onAddFriendRequest(
    AddFriendRequest event,
    Emitter<SearchState> emit,
  ) async {
    // Preserve current users from state for re-display
    final currentUsers = state is SearchLoaded
        ? (state as SearchLoaded).users
        : <UserProfileModel>[];

    try {
      final result = await repository.addFriendRequest(
        event.senderId,
        event.senderName,
        event.receiverId,
      );
      emit(FriendRequestSent(result, currentUsers));
    } on Exception catch (e) {
      emit(SearchError('Failed to add friend request: $e'));
    }
  }
}
