import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';

/// Central control column containing game controls and utilities.
/// Displays reset button, timer widget, and dice icon.
/// Positioned between the two player columns for easy access.
class CenterControlColumn extends StatelessWidget {
  const CenterControlColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(
            Icons.refresh,
            color: AppColors.neutral60,
            size: 40,
          ),
          onPressed: () => context.read<GameBloc>().add(const GameResetEvent()),
        ),
        IconButton(
          onPressed: () =>
              context.read<GameBloc>().state.status == GameStatus.paused
                  ? context.read<GameBloc>().add(const GameResumeEvent())
                  : context.read<GameBloc>().add(const GamePauseEvent()),
          icon: Icon(
            context.watch<GameBloc>().state.status == GameStatus.paused
                ? Icons.play_circle_outline_outlined
                : Icons.pause_circle_outline_rounded,
            size: 40,
            color: AppColors.neutral60,
          ),
        ),
        const TimerWidget(),
        const Icon(
          FontAwesomeIcons.diceOne,
          size: 30,
          color: AppColors.neutral60,
        ),
        IconButton(
          onPressed: () => GoRouter.of(context).go(HomePage.routeName),
          icon: const Icon(
            Icons.home_filled,
            size: 40,
            color: AppColors.neutral60,
          ),
        ),
      ],
    );
  }
}
