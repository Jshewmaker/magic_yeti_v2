import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magic_yeti/app/utils/device_info_provider.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/tracker/bloc/tracker_bloc.dart';
import 'package:magic_yeti/tracker/tracker.dart';

class TrackerWidgets extends StatelessWidget {
  const TrackerWidgets({
    required this.rotate,
    required this.playerId,
    required this.leftSideTracker,
    super.key,
  });

  final bool rotate;

  /// Player who owns the tracker.
  final String playerId;

  /// Whether this is the left or right side of the screen.
  final bool leftSideTracker;

  @override
  Widget build(BuildContext context) {
    context.select<GameBloc, List<(String?, String?)>>(
      (bloc) => bloc.state.playerList
          .map(
            (player) => (
              player.commander?.imageUrl,
              player.partner?.imageUrl,
            ),
          )
          .toList(),
    );

    final players = context.read<GameBloc>().state.playerList;
    final trackerSize = DeviceInfoProvider.of(context).isPhone ? 60.0 : 90.0;
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
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.transparent.withValues(alpha: .8),
                borderRadius:
                    (leftSideTracker && rotate) || (!leftSideTracker && !rotate)
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          )
                        : const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
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
                            const SizedBox(
                              height: AppSpacing.xs,
                            ),
                          ],
                        );
                      },
                    ),
                  ...state.icons.map(
                    (icon) => Column(
                      children: [
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
                        const SizedBox(
                          height: AppSpacing.xs,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        child: Container(
                          width: trackerSize,
                          height: trackerSize,
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
                      const SizedBox(
                        height: AppSpacing.xs,
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
            width: 500,
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
                      ...iconMap.entries.map(
                        (entry) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: FaIcon(entry.key),
                              onPressed: () =>
                                  Navigator.pop(context, entry.key),
                            ),
                            Text(
                              entry.value,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                              ),
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
      },
    );
  }
}

Map<IconData, String> iconMap = {
  FontAwesomeIcons.droplet: 'Island',
  FontAwesomeIcons.skull: 'Swamp',
  FontAwesomeIcons.fire: 'Mountain',
  FontAwesomeIcons.sun: 'Plains',
  FontAwesomeIcons.tree: 'Forest',
  FontAwesomeIcons.diamond: 'Colorless',
  FontAwesomeIcons.dungeon: 'Dungeon Level',
  FontAwesomeIcons.skullCrossbones: 'Poison',
  FontAwesomeIcons.boltLightning: 'Energy',
  FontAwesomeIcons.radiation: 'Radiation',
  FontAwesomeIcons.brain: 'Experience',
};
