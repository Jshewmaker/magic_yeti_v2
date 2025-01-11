part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.games = const [],
    this.error,
  });

  final HomeStatus status;
  final List<GameModel> games;
  final String? error;

  HomeState copyWith({
    HomeStatus? status,
    List<GameModel>? games,
    String? error,
  }) {
    return HomeState(
      status: status ?? this.status,
      games: games ?? this.games,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, games, error];
}
