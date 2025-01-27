import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:player_repository/models/models.dart';

class CommanderDamageTracker extends StatelessWidget {
  const CommanderDamageTracker({
    required this.playerId,
    required this.player,
    required this.commanderPlayerId,
    super.key,
  });

  final String playerId;
  final String commanderPlayerId;
  final Player player;

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
            SizedBox(
              width: width,
              height: height,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: player.commander?.imageUrl.isEmpty ?? true
                    ? Container(
                        color: Color(player.color).withValues(alpha: .8),
                        width: width,
                        height: height,
                      )
                    : player.partner?.imageUrl == null
                        ? Image.network(
                            player.commander?.imageUrl ?? '',
                            width: width,
                            height: height,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color:
                                    Color(player.color).withValues(alpha: .8),
                                width: width,
                                height: height,
                              );
                            },
                            fit: BoxFit.cover,
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Image.network(
                                  player.commander?.imageUrl ?? '',
                                  fit: BoxFit.fitHeight,
                                  opacity: AlwaysStoppedAnimation(
                                    player.lifePoints <= 0 ? .2 : 1,
                                  ),
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Color(player.color).withValues(
                                          alpha:
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
                              Expanded(
                                child: Image.network(
                                  player.partner?.imageUrl ?? '',
                                  fit: BoxFit.fitHeight,
                                  opacity: AlwaysStoppedAnimation(
                                    player.lifePoints <= 0 ? .2 : 1,
                                  ),
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Color(player.color).withValues(
                                          alpha:
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
                            ],
                          ),
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
