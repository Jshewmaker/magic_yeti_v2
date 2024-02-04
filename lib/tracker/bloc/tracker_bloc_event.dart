part of 'tracker_bloc_bloc.dart';

sealed class TrackerBlocEvent extends Equatable {
  const TrackerBlocEvent();

  @override
  List<Object> get props => [];
}

class TrackerBlocIncremented extends TrackerBlocEvent {}

class TrackerBlocDecremented extends TrackerBlocEvent {}

class TrackerBlocStopDecrement extends TrackerBlocEvent {}
