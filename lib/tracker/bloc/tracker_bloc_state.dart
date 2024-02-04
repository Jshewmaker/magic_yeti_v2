part of 'tracker_bloc_bloc.dart';

class TrackerBlocState extends Equatable {
  const TrackerBlocState({required this.counter});

  final int counter;

  @override
  List<Object> get props => [counter];
}

class TrackingBlockTimerInProgress extends TrackerBlocState {
  const TrackingBlockTimerInProgress({required super.counter});
}
