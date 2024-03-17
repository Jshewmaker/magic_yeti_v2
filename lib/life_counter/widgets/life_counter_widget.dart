import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app_router/routes.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/player/player.dart';

class LifeCounterWidget extends StatelessWidget {
  LifeCounterWidget({
    required this.player,
    super.key,
  });
  final Player player;
  final textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    textController.text = player.name;
    final dead = player.lifePoints < 1;
    return BlocConsumer<PlayerBloc, PlayerState>(
      listener: (context, state) {
        context.read<GameBloc>().add(UpdatePlayerEvent(player: state.player!));
      },
      builder: (context, state) {
        return RotatedBox(
          quarterTurns: player.playerNumber < 2 ? 0 : 2,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: Image.network(
                  player.picture,
                  opacity: AlwaysStoppedAnimation(dead ? .2 : 1),
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: Color(player.color).withOpacity(dead ? 0 : 1),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
              ),
              Center(
                child: StrokeText(
                  text: '${player.lifePoints}',
                  fontSize: 96,
                  color: dead ? AppColors.black : AppColors.white,
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
                            UpdatePlayerLifeEvent(
                              player: player,
                              decrement: true,
                            ),
                          ),
                      onLongPressUp: () =>
                          context.read<PlayerBloc>().add(PlayerStopDecrement()),
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
                      onLongPress: () => context
                          .read<PlayerBloc>()
                          .add(UpdatePlayerLifeByXEvent(
                            player: player,
                            decrement: false,
                          )),
                      onLongPressUp: () =>
                          context.read<PlayerBloc>().add(PlayerStopDecrement()),
                    ),
                  ),
                ],
              ),
              _PlayerNameWidget(
                name: textController.text,
                onPressed: () {
                  context.pushNamed(
                    const CustomizePlayerRoute().name,
                    extra: player,
                  );
                },
              ),
            ],
          ),
        );
      },
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
