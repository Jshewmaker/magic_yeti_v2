part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

/// A search-box submission. The bloc decides whether [query] looks like a
/// friend code or a username and dispatches accordingly.
class SearchSubmitted extends SearchEvent {
  const SearchSubmitted(this.query, this.currentUserId);
  final String query;
  final String currentUserId;

  @override
  List<Object> get props => [query, currentUserId];
}

/// Sends (or accepts, for a mutual pending) a friend request from
/// [senderId] to [receiverId]. The bloc looks up the sender's own profile
/// to denormalize the real username/friend code onto the request — the
/// UI never passes a display name directly, so it can't accidentally send
/// the wrong one (e.g. a stale Firebase Auth display name).
class AddFriendRequest extends SearchEvent {
  const AddFriendRequest(
    this.senderId,
    this.receiverId,
  );
  final String senderId;
  final String receiverId;

  @override
  List<Object> get props => [senderId, receiverId];
}
