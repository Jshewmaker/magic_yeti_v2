import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';

class CommanderDamageTracker extends StatelessWidget {
  const CommanderDamageTracker({
    required this.imageUrl,
    required this.color,
    required this.playerId,
    required this.commanderPlayerId,
    super.key,
  });

  final String playerId;
  final String commanderPlayerId;
  final String imageUrl;
  final int color;

  @override
  Widget build(BuildContext context) {
    const width = 70.0;
    const height = 70.0;

    final commanderDamage = context.select<PlayerBloc, int>(
      (bloc) => bloc.state.player.commanderDamageList[commanderPlayerId] ?? 0,
    );

    return GestureDetector(
      onTap: () {
        context.read<PlayerBloc>().add(
              UpdatePlayerLifeEvent(decrement: true, playerId: playerId),
            );
        context.read<PlayerBloc>().add(
              PlayerCommanderDamageIncremented(
                commanderId: commanderPlayerId,
              ),
            );
      },
      onLongPress: () {
        context.read<PlayerBloc>().add(
              UpdatePlayerLifeEvent(decrement: false, playerId: playerId),
            );
        context.read<PlayerBloc>().add(
              PlayerCommanderDamageDecremented(
                commanderId: commanderPlayerId,
              ),
            );
      },
      onLongPressUp: () => context.read<PlayerBloc>().add(
            const PlayerStopDecrement(),
          ),
      child: Container(
        padding: const EdgeInsets.only(top: 5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: imageUrl.isEmpty
                  ? Container(
                      color: Color(color).withOpacity(1),
                      width: width,
                      height: height,
                    )
                  : Image.network(
                      imageUrl,
                      width: width,
                      height: height,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Color(color).withOpacity(1),
                          width: width,
                          height: height,
                        );
                      },
                      fit: BoxFit.cover,
                    ),
            ),
            StrokeText(
              text: commanderDamage.toString(),
              fontSize: 28,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
