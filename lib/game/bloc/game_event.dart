part of 'game_bloc.dart';

sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

final class GameOverEvent extends GameEvent {
  const GameOverEvent({required this.player});

  final List<Player> player;
}
