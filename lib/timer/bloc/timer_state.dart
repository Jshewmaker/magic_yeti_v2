part of 'timer_bloc.dart';

enum TimerStatus { initial, running, paused }

class TimerState extends Equatable {
  const TimerState({
    this.status = TimerStatus.initial,
    this.elapsedSeconds = 0,
    this.startTime,
  });

  final TimerStatus status;
  final int elapsedSeconds;
  final DateTime? startTime;

  TimerState copyWith({
    TimerStatus? status,
    int? elapsedSeconds,
    DateTime? startTime,
  }) {
    return TimerState(
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  List<Object?> get props => [
        status,
        elapsedSeconds,
        startTime,
      ];
}
