part of 'counter_bloc.dart';

sealed class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object> get props => [];
}

class CounterIncrementPressed extends CounterEvent {
  const CounterIncrementPressed();
}

class CounterDecrementPressed extends CounterEvent {
  const CounterDecrementPressed();
}

class CounterStopDecrementing extends CounterEvent {
  const CounterStopDecrementing();
}

/// Fired by the hold-to-decrement timer.
class _CounterRepeatTicked extends CounterEvent {
  const _CounterRepeatTicked();
}
