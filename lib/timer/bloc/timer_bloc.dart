import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'timer_event.dart';
part 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  TimerBloc() : super(const TimerState()) {
    on<TimerStartEvent>(_onTimerStart);
    on<TimerPauseEvent>(_onTimerPause);
    on<TimerResumeEvent>(_onTimerResume);
    on<TimerResetEvent>(_onTimerReset);
    on<TimerTickEvent>(_onTimerTick);
  }

  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(TimerTickEvent(elapsedSeconds: state.elapsedSeconds + 1)),
    );
  }

  void _onTimerStart(
    TimerStartEvent event,
    Emitter<TimerState> emit,
  ) {
    _startTimer();
    emit(
      state.copyWith(
        status: TimerStatus.running,
        elapsedSeconds: 0,
        startTime: DateTime.now(),
      ),
    );
  }

  void _onTimerPause(
    TimerPauseEvent event,
    Emitter<TimerState> emit,
  ) {
    _timer?.cancel();
    emit(state.copyWith(status: TimerStatus.paused));
  }

  void _onTimerResume(
    TimerResumeEvent event,
    Emitter<TimerState> emit,
  ) {
    _startTimer();
    emit(state.copyWith(status: TimerStatus.running));
  }

  void _onTimerReset(
    TimerResetEvent event,
    Emitter<TimerState> emit,
  ) {
    _timer?.cancel();
    emit(
      state.copyWith(
        status: TimerStatus.initial,
        elapsedSeconds: 0,
        startTime: null,
      ),
    );
  }

  void _onTimerTick(
    TimerTickEvent event,
    Emitter<TimerState> emit,
  ) {
    emit(state.copyWith(elapsedSeconds: event.elapsedSeconds));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
