part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class SearchUsers extends SearchEvent {
  const SearchUsers(this.query);
  final String query;

  @override
  List<Object> get props => [query];
}

class AddFriendRequest extends SearchEvent {
  const AddFriendRequest(
    this.senderId,
    this.senderName,
    this.receiverId,
  );
  final String senderId;
  final String senderName;
  final String receiverId;

  @override
  List<Object> get props => [senderId, senderName, receiverId];
}
