import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'tracker_bloc_event.dart';
part 'tracker_bloc_state.dart';

class TrackerBloc extends Bloc<TrackerBlocEvent, TrackerBlocState> {
  TrackerBloc() : super(const TrackerBlocState(counter: 0)) {
    on<TrackerBlocIncremented>(_onTrackerIncremented);
    on<TrackerBlocDecremented>(_onTrackerDecremented);
    on<TrackerBlocStopDecrement>(_onStopDecrementing);
  }
  Timer? _timer;

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void _onTrackerIncremented(
    TrackerBlocEvent event,
    Emitter<TrackerBlocState> emit,
  ) {
    emit(TrackerBlocState(counter: state.counter + 1));
  }

  void _onTrackerDecremented(
    TrackerBlocEvent event,
    Emitter<TrackerBlocState> emit,
  ) {
    emit(TrackingBlockTimerInProgress(counter: state.counter - 1));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      add(TrackerBlocDecremented());
    });
  }

  void _onStopDecrementing(
    TrackerBlocEvent event,
    Emitter<TrackerBlocState> emit,
  ) {
    _timer?.cancel();
    emit(TrackerBlocState(counter: state.counter));
  }
}
