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
