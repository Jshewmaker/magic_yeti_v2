part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class SearchByFriendCode extends SearchEvent {
  const SearchByFriendCode(this.friendCode, this.currentUserId);
  final String friendCode;
  final String currentUserId;

  @override
  List<Object> get props => [friendCode, currentUserId];
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
