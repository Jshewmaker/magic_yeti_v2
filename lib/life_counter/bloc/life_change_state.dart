part of 'life_change_bloc.dart';

class LifeChangeState extends Equatable {
  const LifeChangeState({this.change});

  final int? change;

  LifeChangeState copyWith({
    int? change,
  }) {
    return LifeChangeState(
      change: change ?? this.change,
    );
  }

  @override
  List<Object?> get props => [change];
}
