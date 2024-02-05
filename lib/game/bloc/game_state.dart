part of 'game_bloc.dart';

sealed class GameState extends Equatable {
  const GameState();

  @override
  List<Object> get props => [];
}

final class GameInitialState extends GameState {}

final class GameLoadingState extends GameState {}

final class GameIdleState extends GameState {}

final class GameFailureState extends GameState {}
