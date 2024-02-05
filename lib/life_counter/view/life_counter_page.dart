import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:magic_yeti/tracker/tracker.dart';

class LifeCounterPage extends StatelessWidget {
  const LifeCounterPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;
    return BlocListener<PlayerBloc, PlayerState>(
      listener: (context, state) {
        if (state.status == PlayerStatus.died &&
            state.playerList.any((element) => element.lifePoints < 1)) {
          final player = state.playerList
              .where((element) => element.lifePoints < 1)
              .toList();
          if (player.length == 3) {
            context
                .read<GameBloc>()
                .add(GameOverEvent(player: state.playerList));
          }
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        LifeCounterWidget(
                          player: state.playerList[3],
                        ),
                        TrackerWidgets(
                          rotate: false,
                          player: state.playerList[3].playerNumber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: Stack(
                      children: [
                        LifeCounterWidget(
                          player: state.playerList[1],
                        ),
                        TrackerWidgets(
                          rotate: true,
                          player: state.playerList[1].playerNumber,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(
                  Icons.refresh,
                  size: 50,
                ),
                TimerWidget(),
                Icon(
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
                          player: state.playerList[2],
                        ),
                        TrackerWidgets(
                          rotate: false,
                          player: state.playerList[2].playerNumber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        LifeCounterWidget(
                          player: state.playerList[0],
                        ),
                        TrackerWidgets(
                          rotate: true,
                          player: state.playerList[0].playerNumber,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
