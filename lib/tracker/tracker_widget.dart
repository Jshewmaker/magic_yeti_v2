import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/tracker/bloc/tracker_bloc.dart';
import 'package:magic_yeti/tracker/tracker.dart';
import 'package:player_repository/models/models.dart';

class TrackerWidgets extends StatelessWidget {
  const TrackerWidgets({
    required this.rotate,
    required this.playerId,
    super.key,
  });

  final bool rotate;

  /// Player who owns the tracker.
  final String playerId;

  @override
  Widget build(BuildContext context) {
    final players = context.select<GameBloc, List<Player>>(
      (bloc) => bloc.state.playerList.map((player) => player).toList(),
    );

    return BlocProvider(
      create: (context) => TrackerBloc(),
      child: BlocBuilder<TrackerBloc, TrackerState>(
        builder: (context, state) {
          final status = context.select<GameBloc, GameStatus>(
            (bloc) => bloc.state.status,
          );

          if (status == GameStatus.reset) {
            context.read<TrackerBloc>().add(const ResetTrackerIcons());
          }
          return RotatedBox(
            quarterTurns: rotate ? 0 : 2,
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.transparent.withValues(alpha: .8),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: ListView(
                children: [
                  if (players.length > 2)
                    ...players.map(
                      (player) {
                        return Column(
                          children: [
                            CommanderDamageTracker(
                              player: player,
                              commanderPlayerId: player.id,
                              playerId: playerId,
                            ),
                          ],
                        );
                      },
                    ),
                  ...state.icons.map(
                    (icon) => Column(
                      children: [
                        const SizedBox(
                          height: AppSpacing.xs,
                        ),
                        Dismissible(
                          onDismissed: (_) => context
                              .read<TrackerBloc>()
                              .add(RemoveTrackerIcon(icon)),
                          key: Key('$icon'),
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            child: CounterTrackerWidget(
                              icon: Icon(
                                icon,
                                size: 40,
                                color: AppColors.white.withValues(alpha: .5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(
                        height: AppSpacing.xs,
                      ),
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: AppColors.white.withValues(alpha: .5),
                          child: IconButton(
                            icon: const Icon(
                              FontAwesomeIcons.plus,
                              color: AppColors.white,
                            ),
                            onPressed: () async {
                              final icon = await _dialogBuilder(context);
                              if (icon != null) {
                                context
                                    .read<TrackerBloc>()
                                    .add(AddTrackerIcon(icon));
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<IconData?> _dialogBuilder(BuildContext context) {
    return showDialog<IconData>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            height: 300,
            width: 300,
            child: Column(
              children: [
                const Text(
                  'Tap an icon to add it to the tracker.',
                  style: TextStyle(color: AppColors.white),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 5,
                    children: [
                      ...iconList.map(
                        (icon) => IconButton(
                          icon: FaIcon(icon),
                          onPressed: () => Navigator.pop(context, icon),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

List<IconData> iconList = [
  FontAwesomeIcons.droplet,
  FontAwesomeIcons.skull,
  FontAwesomeIcons.fire,
  FontAwesomeIcons.sun,
  FontAwesomeIcons.tree,
  FontAwesomeIcons.diamond,
  FontAwesomeIcons.dungeon,
  FontAwesomeIcons.skullCrossbones,
  FontAwesomeIcons.boltLightning,
];
