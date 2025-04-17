import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/life_counter.dart';
import 'package:magic_yeti/life_counter/view/game_over_page.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  factory GamePage.pageBuilder(_, __) {
    return const GamePage(
      key: Key('game_page'),
    );
  }

  static const routeName = 'game_page';
  static String get routePath => '/game_page';

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameBloc>().state;
    final playerCount = gameState.playerList.length;
    if (gameState.playerList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocListener<GameBloc, GameState>(
      listener: (context, state) {
        if (state.status == GameStatus.finished) {
          context.read<TimerBloc>().add(const TimerPauseEvent());
          final gameLength = context.read<TimerBloc>().state.elapsedSeconds;
          context
              .read<GameBloc>()
              .add(GameUpdateTimerEvent(gameLength: gameLength));

          context.go(GameOverPage.routePath);
        }
      },
      child: playerCount == 2 ? const TwoPlayerGame() : const FourPlayerGame(),
    );
  }
}
