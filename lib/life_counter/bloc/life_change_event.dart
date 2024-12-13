part of 'life_change_bloc.dart';

abstract class LifeChangeEvent extends Equatable {
  const LifeChangeEvent();

  @override
  List<Object?> get props => [];
}

class LifePointsChanged extends LifeChangeEvent {
  const LifePointsChanged({
    required this.previousLifePoints,
    required this.newLifePoints,
  });

  final int previousLifePoints;
  final int newLifePoints;

  @override
  List<Object> get props => [previousLifePoints, newLifePoints];
}

class LifePointChangeCompleted extends LifeChangeEvent {
  const LifePointChangeCompleted();
}
