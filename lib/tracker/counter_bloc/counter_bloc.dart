import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'counter_event.dart';
part 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState()) {
    on<CounterIncrementPressed>(_onCounterIncremented);
    on<CounterDecrementPressed>(_onCounterDecremented);
    on<CounterStopDecrementing>(_onStopDecrementing);
  }

  Timer? _timer;

  void _onCounterIncremented(
    CounterIncrementPressed event,
    Emitter<CounterState> emit,
  ) {
    emit(state.copyWith(counter: state.counter + 1));
  }

  void _onCounterDecremented(
    CounterDecrementPressed event,
    Emitter<CounterState> emit,
  ) {
    emit(const CounterState(status: CounterStatus.loading));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      add(CounterDecrementPressed());
    });
  }

  void _onStopDecrementing(
    CounterStopDecrementing event,
    Emitter<CounterState> emit,
  ) {
    _timer?.cancel();
    emit(state.copyWith(counter: 0));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
