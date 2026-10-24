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
    on<_CounterRepeatTicked>((_, emit) => _decrementOnce(emit));
  }

  /// How often the counter drops by one while the tile is held down.
  static const repeatInterval = Duration(milliseconds: 500);

  Timer? _timer;

  void _onCounterIncremented(
    CounterIncrementPressed event,
    Emitter<CounterState> emit,
  ) {
    emit(state.copyWith(counter: state.counter + 1));
  }

  /// Drops the counter by one, then keeps dropping it every
  /// [repeatInterval] until [CounterStopDecrementing]. Counters (poison,
  /// energy, and so on) never go below zero.
  void _onCounterDecremented(
    CounterDecrementPressed event,
    Emitter<CounterState> emit,
  ) {
    _decrementOnce(emit);
    _timer?.cancel();
    _timer = Timer.periodic(
      repeatInterval,
      (_) => add(const _CounterRepeatTicked()),
    );
  }

  void _decrementOnce(Emitter<CounterState> emit) {
    if (state.counter > 0) {
      emit(state.copyWith(counter: state.counter - 1));
    }
  }

  void _onStopDecrementing(
    CounterStopDecrementing event,
    Emitter<CounterState> emit,
  ) {
    _timer?.cancel();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
