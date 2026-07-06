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
    on<SearchSubmitted>(_onSearchSubmitted);
    on<AddFriendRequest>(_onAddFriendRequest);
  }
  final FirebaseDatabaseRepository repository;

  /// Friend codes are a plain 8-character A-Z0-9 string (see
  /// [FirebaseDatabaseRepository.generateUniqueFriendCode]) — plus the
  /// legacy `YETI-` + 4-character shape already issued to existing users
  /// before that format changed. Anything else typed into the search box
  /// is treated as a username query instead.
  static final RegExp _friendCodePattern =
      RegExp(r'^(YETI-[A-Z0-9]{4}|[A-Z0-9]{8})$');

  static bool _looksLikeFriendCode(String query) =>
      _friendCodePattern.hasMatch(query.trim().toUpperCase());

  Future<void> _onSearchSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      if (_looksLikeFriendCode(event.query)) {
        final result = await repository.searchByFriendCode(event.query);
        if (result.found && result.user != null) {
          emit(
            SearchLoaded([
              UserSearchMatch(
                user: result.user!,
                relationship: result.relationship ?? RelationshipStatus.none,
              ),
            ]),
          );
          return;
        }
        // Not found as a code — an 8-character string could coincidentally
        // also be a real username, so fall through to a name search
        // rather than reporting a false "no user found".
      }
      final matches = await repository.searchByUsername(event.query);
      emit(SearchLoaded(matches));
      // The repository throws ArgumentError for a callable
      // `invalid-argument` response (e.g. an empty/too-short query);
      // surface it the same as any other search failure instead of
      // crashing the bloc.
      // ignore: avoid_catching_errors
    } on ArgumentError catch (e) {
      emit(SearchError('Failed to search: $e'));
    } on Exception catch (e) {
      emit(SearchError('Failed to search: $e'));
    }
  }

  Future<void> _onAddFriendRequest(
    AddFriendRequest event,
    Emitter<SearchState> emit,
  ) async {
    // Preserve the current matches for re-display, updating only the
    // entry the request was actually sent to/accepted from — a name
    // search can have several results on screen at once.
    final currentMatches = state is SearchLoaded
        ? (state as SearchLoaded).matches
        : <UserSearchMatch>[];

    try {
      // The UI only ever knows the sender's id — the real username/friend
      // code to denormalize onto the request comes from the sender's own
      // profile, not a display name passed in from the caller.
      final senderProfile = await repository.getUserProfileOnce(
        event.senderId,
      );
      final result = await repository.addFriendRequest(
        event.senderId,
        senderProfile?.username ?? '',
        senderProfile?.friendCode,
        event.receiverId,
      );
      final updatedStatus = switch (result) {
        FriendRequestResult.sent => RelationshipStatus.pendingSent,
        FriendRequestResult.autoAccepted => RelationshipStatus.friends,
        FriendRequestResult.alreadyFriends => RelationshipStatus.friends,
        FriendRequestResult.alreadyPending => RelationshipStatus.pendingSent,
        FriendRequestResult.self => RelationshipStatus.self,
      };
      final updatedMatches = [
        for (final match in currentMatches)
          if (match.user.id == event.receiverId)
            UserSearchMatch(user: match.user, relationship: updatedStatus)
          else
            match,
      ];
      emit(FriendRequestSent(result, updatedMatches));
    } on Exception catch (e) {
      emit(SearchError('Failed to add friend request: $e'));
    }
  }
}
