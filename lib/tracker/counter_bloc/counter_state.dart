part of 'counter_bloc.dart';

enum CounterStatus {
  initial,
  loading,
  success,
  error,
}

class CounterState extends Equatable {
  const CounterState({
    this.status = CounterStatus.initial,
    this.counter = 0,
    this.error,
  });

  final CounterStatus status;
  final int counter;
  final String? error;

  CounterState copyWith({
    CounterStatus? status,
    int? counter,
    String? error,
  }) {
    return CounterState(
      status: status ?? this.status,
      counter: counter ?? this.counter,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        counter,
        error,
      ];
}
