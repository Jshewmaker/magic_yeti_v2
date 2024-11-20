import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/view/customize_player_page.dart';

class LifeCounterWidget extends StatelessWidget {
  LifeCounterWidget({
    required this.playerIndex,
    this.rotate = false,
    super.key,
  });
  final bool rotate;
  final int playerIndex;
  final textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final player = context.select(
      (GameBloc bloc) => bloc.state.playerList[playerIndex],
    );
    textController.text = player.name;
    return BlocProvider(
      create: (context) => PlayerBloc(player: player),
      child: BlocConsumer<PlayerBloc, PlayerState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == PlayerStatus.died) {
            context.read<GameBloc>().add(
                  UpdatePlayerEvent(
                    player: state.player,
                    action: PlayerAction.died,
                  ),
                );
          }
        },
        builder: (context, state) {
          return RotatedBox(
            quarterTurns: rotate ? 2 : 0,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: Image.network(
                    player.picture,
                    opacity: AlwaysStoppedAnimation(
                      player.lifePoints <= 0 ? .2 : 1,
                    ),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Color(player.color).withOpacity(
                            player.lifePoints <= 0 ? .3 : 1,
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Center(
                  child: StrokeText(
                    text: '${player.lifePoints}',
                    fontSize: 96,
                    color: player.lifePoints <= 0
                        ? AppColors.black
                        : AppColors.white,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      key: const ValueKey(
                        'life_counter_widget_decrement',
                      ),
                      child: GestureDetector(
                        onTap: () => context.read<PlayerBloc>().add(
                              UpdatePlayerLifeEvent(
                                player: player,
                                decrement: true,
                              ),
                            ),
                        onLongPress: () => context.read<PlayerBloc>().add(
                              UpdatePlayerLifeByXEvent(
                                player: player,
                                decrement: true,
                              ),
                            ),
                        onLongPressUp: () => context.read<PlayerBloc>().add(
                              PlayerStopDecrement(
                                player: player,
                              ),
                            ),
                      ),
                    ),
                    Expanded(
                      key: const ValueKey(
                        'life_counter_widget_increment',
                      ),
                      child: GestureDetector(
                        onTap: () => context.read<PlayerBloc>().add(
                              UpdatePlayerLifeEvent(
                                player: player,
                                decrement: false,
                              ),
                            ),
                        onLongPress: () => context.read<PlayerBloc>().add(
                              UpdatePlayerLifeByXEvent(
                                player: player,
                                decrement: false,
                              ),
                            ),
                        onLongPressUp: () => context.read<PlayerBloc>().add(
                              PlayerStopDecrement(
                                player: player,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
                _PlayerNameWidget(
                  name: textController.text,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            CustomizePlayerPage(player: player),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlayerNameWidget extends StatelessWidget {
  const _PlayerNameWidget({required this.onPressed, required this.name});
  final void Function()? onPressed;
  final String name;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all(Colors.white.withOpacity(.8)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          onPressed: onPressed,
          child: Text(name),
        ),
      ],
    );
  }
}
