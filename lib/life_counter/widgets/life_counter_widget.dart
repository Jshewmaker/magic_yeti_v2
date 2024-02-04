import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app_router/app_router.dart';
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
    return RotatedBox(
      quarterTurns: player.playerNumber < 2 ? 0 : 2,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: Image.network(
              player.picture,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  color: player.color,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ),
          ),
          Center(
            child: StrokeText(
              text: '${player.lifePoints}',
              fontSize: 96,
              color: AppColors.white,
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
                          playerNumber: player.playerNumber,
                          decrement: true,
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
                          playerNumber: player.playerNumber,
                          decrement: false,
                        ),
                      ),
                ),
              ),
            ],
          ),
          _PlayerNameWidget(
            name: textController.text,
            onPressed: () {
              context.pushNamed(
                const CustomizePlayerRoute().name,
                pathParameters: {
                  'player': player.playerNumber.toString(),
                },
              );
            },
          ),
        ],
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
