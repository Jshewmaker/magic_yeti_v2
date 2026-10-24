import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/tracker/counter_bloc/counter_bloc.dart';

void main() {
  group('CounterBloc', () {
    test('starts at zero', () {
      expect(CounterBloc().state.counter, 0);
    });

    blocTest<CounterBloc, CounterState>(
      'adds one on each increment',
      build: CounterBloc.new,
      act: (bloc) => bloc
        ..add(const CounterIncrementPressed())
        ..add(const CounterIncrementPressed()),
      expect: () => const [
        CounterState(counter: 1),
        CounterState(counter: 2),
      ],
    );

    blocTest<CounterBloc, CounterState>(
      'subtracts one when a hold starts',
      build: CounterBloc.new,
      seed: () => const CounterState(counter: 3),
      act: (bloc) => bloc
        ..add(const CounterDecrementPressed())
        ..add(const CounterStopDecrementing()),
      expect: () => const [CounterState(counter: 2)],
    );

    blocTest<CounterBloc, CounterState>(
      'keeps subtracting while held, and stops on release',
      build: CounterBloc.new,
      seed: () => const CounterState(counter: 5),
      act: (bloc) async {
        bloc.add(const CounterDecrementPressed());
        await Future<void>.delayed(
          CounterBloc.repeatInterval * 2 + const Duration(milliseconds: 50),
        );
        bloc.add(const CounterStopDecrementing());
        await Future<void>.delayed(CounterBloc.repeatInterval * 2);
      },
      expect: () => const [
        CounterState(counter: 4),
        CounterState(counter: 3),
        CounterState(counter: 2),
      ],
    );

    blocTest<CounterBloc, CounterState>(
      'never goes below zero',
      build: CounterBloc.new,
      act: (bloc) => bloc
        ..add(const CounterDecrementPressed())
        ..add(const CounterStopDecrementing()),
      expect: () => const <CounterState>[],
    );
  });
}
