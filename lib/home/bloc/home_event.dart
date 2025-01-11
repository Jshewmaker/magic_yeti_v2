part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

/// Event to load match history
final class LoadMatchHistory extends HomeEvent {
  const LoadMatchHistory();
}
