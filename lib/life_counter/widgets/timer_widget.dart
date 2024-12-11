import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 1,
      child: BlocSelector<GameBloc, GameState, int>(
        selector: (state) => state.elapsedSeconds,
        builder: (context, elapsedSeconds) {
          return GestureDetector(
            onTap: () =>
                context.read<GameBloc>().state.status == GameStatus.paused
                    ? context.read<GameBloc>().add(const GameResumeEvent())
                    : context.read<GameBloc>().add(const GamePauseEvent()),
            child: Row(
              children: [
                if (context.watch<GameBloc>().state.status == GameStatus.paused)
                  const Icon(
                    Icons.pause,
                    color: AppColors.neutral60,
                    size: 40,
                  )
                else
                  Text(
                    '${(elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}',
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
