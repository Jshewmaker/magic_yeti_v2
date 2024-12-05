import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';
import 'package:magic_yeti/tracker/tracker.dart';

class FourPlayerPage extends StatelessWidget {
  const FourPlayerPage({super.key});

  factory FourPlayerPage.pageBuilder(_, __) {
    return const FourPlayerPage(
      key: Key('life_counter_page'),
    );
  }

  static const routeName = 'life_counter_page';
  static String get routePath => '/life_counter_page';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Stack(
          children: [
            const FourPlayerView(),
            if (state.status == GameStatus.finished) const GameOverWidget(),
          ],
        );
      },
    );
  }
}

@visibleForTesting
class FourPlayerView extends StatelessWidget {
  const FourPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerList = context.read<GameBloc>().state.playerList;
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      LifeCounterWidget(
                        playerId: playerList[3].id,
                        rotate: true,
                      ),
                      const TrackerWidgets(
                        rotate: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Stack(
                    children: [
                      LifeCounterWidget(playerId: playerList[1].id),
                      const TrackerWidgets(
                        rotate: true,
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
                      LifeCounterWidget(
                        playerId: playerList[2].id,
                        rotate: true,
                      ),
                      const TrackerWidgets(
                        rotate: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      LifeCounterWidget(playerId: playerList[0].id),
                      const TrackerWidgets(
                        rotate: true,
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
