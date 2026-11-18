part of 'timer_bloc.dart';

abstract class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object?> get props => [];
}

class TimerStartEvent extends TimerEvent {
  const TimerStartEvent();
}

class TimerPauseEvent extends TimerEvent {
  const TimerPauseEvent();
}

class TimerResumeEvent extends TimerEvent {
  const TimerResumeEvent();
}

class TimerResetEvent extends TimerEvent {
  const TimerResetEvent();
}

class TimerTickEvent extends TimerEvent {
  const TimerTickEvent({required this.elapsedSeconds});
  final int elapsedSeconds;

  @override
  List<Object> get props => [elapsedSeconds];
}
