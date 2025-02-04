import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 1,
      child: BlocBuilder<TimerBloc, TimerState>(
        builder: (context, state) {
          return GestureDetector(
            onTap: () =>
                context.read<TimerBloc>().state.status == TimerStatus.paused
                    ? context.read<TimerBloc>().add(const TimerResumeEvent())
                    : context.read<TimerBloc>().add(const TimerPauseEvent()),
            child: Row(
              children: [
                Text(
                  '${(state.elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(state.elapsedSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.neutral60,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
