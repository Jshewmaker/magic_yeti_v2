part of 'search_bloc.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  const SearchLoaded(this.users);
  final List<UserProfileModel> users;

  @override
  List<Object> get props => [users];
}

class SearchError extends SearchState {
  const SearchError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
