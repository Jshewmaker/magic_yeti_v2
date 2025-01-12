part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

/// Event to load match history
final class LoadMatchHistory extends HomeEvent {
  const LoadMatchHistory({
    required this.userId,
  });

  final String userId;

  @override
  List<Object> get props => [userId];
}

/// Event to clear match history
final class ClearMatchHistory extends HomeEvent {
  const ClearMatchHistory();
}
