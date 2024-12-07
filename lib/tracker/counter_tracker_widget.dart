import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/tracker/counter_bloc/counter_bloc.dart';

class CounterTrackerWidget extends StatelessWidget {
  const CounterTrackerWidget({
    required this.icon,
    super.key,
  });
  final Icon icon;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CounterBloc(),
      child: BlocBuilder<CounterBloc, CounterState>(
        builder: (context, state) {
          return GestureDetector(
            onTap: () =>
                context.read<CounterBloc>().add(CounterIncrementPressed()),
            onLongPress: () =>
                context.read<CounterBloc>().add(CounterDecrementPressed()),
            onLongPressUp: () =>
                context.read<CounterBloc>().add(CounterStopDecrementing()),
            child: Container(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  icon,
                  StrokeText(
                    text: state.counter.toString(),
                    fontSize: 28,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
