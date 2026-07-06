part of 'search_bloc.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  const SearchLoaded(this.matches);
  final List<UserSearchMatch> matches;

  @override
  List<Object> get props => [matches];
}

class FriendRequestSent extends SearchState {
  const FriendRequestSent(this.result, this.matches);
  final FriendRequestResult result;
  final List<UserSearchMatch> matches;

  @override
  List<Object> get props => [result, matches];
}

class SearchError extends SearchState {
  const SearchError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
