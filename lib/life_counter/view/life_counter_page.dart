import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';
import 'package:magic_yeti/tracker/tracker.dart';

class LifeCounterPage extends StatelessWidget {
  const LifeCounterPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {},
      builder: (context, state) {
        state.playerList.sort(
          (a, b) => a.playerNumber.compareTo(b.playerNumber),
        );
        return Stack(
          children: [
            const GameView(),
            if (state.status == GameStatus.gameOver) const GameOverWidget(),
          ],
        );
      },
    );
  }
}

@visibleForTesting
class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerList = context.watch<GameBloc>().state.playerList;
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      LifeCounterWidget(playerIndex: 3, rotate: true),
                      TrackerWidgets(
                        rotate: false,
                        player: playerList[3].playerNumber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Stack(
                    children: [
                      LifeCounterWidget(playerIndex: 1),
                      TrackerWidgets(
                        rotate: true,
                        player: playerList[1].playerNumber,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 50,
                ),
                onPressed: () {
                  context.read<GameBloc>().add(const GameResetEvent());
                },
              ),
              const TimerWidget(),
              const Icon(
                FontAwesomeIcons.diceOne,
                size: 30,
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      LifeCounterWidget(playerIndex: 2, rotate: true),
                      TrackerWidgets(
                        rotate: false,
                        player: playerList[2].playerNumber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      LifeCounterWidget(playerIndex: 0),
                      TrackerWidgets(
                        rotate: true,
                        player: playerList[0].playerNumber,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameOverWidget extends StatelessWidget {
  const GameOverWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withOpacity(.5),
      child: Center(
        child: ElevatedButton(
          onPressed: () => context.read<GameBloc>().add(const GameResetEvent()),
          child: const Text('Play Again'),
        ),
      ),
    );
  }
}
