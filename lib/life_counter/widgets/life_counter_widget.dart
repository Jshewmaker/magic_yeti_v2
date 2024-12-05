import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/view/customize_player_page.dart';
import 'package:player_repository/player_repository.dart';

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
    final playerRepository = context.read<PlayerRepository>();

    return BlocProvider(
      create: (context) => PlayerBloc(
        playerRepository: playerRepository,
      ),
      child: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          final player = playerRepository.getPlayers()[playerIndex];
          textController.text = player.name;
          return RotatedBox(
            quarterTurns: rotate ? 2 : 0,
            child: Stack(
              children: [
                BackgroundWidget(player: player),
                LifePointsWidget(lifePoints: player.lifePoints),
                Column(
                  children: [
                    IncrementLifeWidget(player: player),
                    DecrementLifeWidget(player: player),
                  ],
                ),
                _PlayerNameWidget(
                  name: textController.text,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: context.read<PlayerBloc>(),
                          child: CustomizePlayerPage(
                            playerId: player.id,
                          ),
                        ),
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

class IncrementLifeWidget extends StatelessWidget {
  const IncrementLifeWidget({
    required this.player,
    super.key,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      key: const ValueKey(
        'life_counter_widget_increment',
      ),
      child: GestureDetector(
        onTap: () => context.read<PlayerBloc>().add(
              UpdatePlayerLifeEvent(decrement: false, playerId: player.id),
            ),
        onLongPress: () => context.read<PlayerBloc>().add(
              UpdatePlayerLifeByXEvent(decrement: false, playerId: player.id),
            ),
        onLongPressUp: () => context.read<PlayerBloc>().add(
              const PlayerStopDecrement(),
            ),
      ),
    );
  }
}

class DecrementLifeWidget extends StatelessWidget {
  const DecrementLifeWidget({
    required this.player,
    super.key,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      key: const ValueKey(
        'life_counter_widget_decrement',
      ),
      child: GestureDetector(
        onTap: () => context.read<PlayerBloc>().add(
              UpdatePlayerLifeEvent(
                decrement: true,
                playerId: player.id,
              ),
            ),
        onLongPress: () => context.read<PlayerBloc>().add(
              UpdatePlayerLifeByXEvent(
                decrement: true,
                playerId: player.id,
              ),
            ),
        onLongPressUp: () => context.read<PlayerBloc>().add(
              const PlayerStopDecrement(),
            ),
      ),
    );
  }
}

class LifePointsWidget extends StatelessWidget {
  const LifePointsWidget({
    required this.lifePoints,
    super.key,
  });

  final int lifePoints;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StrokeText(
        text: '$lifePoints',
        fontSize: 96,
        color: lifePoints <= 0 ? AppColors.black : AppColors.white,
      ),
    );
  }
}

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({
    required this.player,
    super.key,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
                WidgetStateProperty.all(Colors.white.withOpacity(.8)),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
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
