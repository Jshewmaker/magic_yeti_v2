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
    final sizes = TrackerSizes.fromDevice(
      isPhone: DeviceInfoProvider.of(context).isPhone,
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .8),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (players.length > 2)
                    ...players.map(
                      (player) {
                        return Row(
                          children: [
                            CommanderDamageTracker(
                              player: player,
                              commanderPlayerId: player.id,
                              playerId: playerId,
                            ),
                            const SizedBox(
                              width: AppSpacing.xs,
                            ),
                          ],
                        );
                      },
                    ),
                  ...state.icons.map(
                    (icon) => Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                          child: CounterTrackerWidget(
                            icon: Icon(
                              icon,
                              size: sizes.iconSize,
                              color: AppColors.white.withValues(alpha: .5),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                        child: Container(
                          width: sizes.tileSize,
                          height: sizes.tileSize,
                          color: AppColors.white.withValues(alpha: .5),
                          child: IconButton(
                            icon: Icon(
                              FontAwesomeIcons.plus,
                              color: AppColors.white,
                              size: sizes.buttonIconSize,
                            ),
                            onPressed: () async {
                              final result = await _dialogBuilder(
                                context,
                                state.icons,
                              );
                              if (result != null && context.mounted) {
                                final (isAdd, icon) = result;
                                context.read<TrackerBloc>().add(
                                  isAdd
                                      ? AddTrackerIcon(icon)
                                      : RemoveTrackerIcon(icon),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: AppSpacing.xs,
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

  Future<(bool, IconData)?> _dialogBuilder(
    BuildContext context,
    List<IconData> currentIcons,
  ) {
    return showDialog<(bool, IconData)>(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            height: 300,
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Select a tracker to add or remove',
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 5,
                    children: [
                      ...iconMap.entries.map(
                        (entry) {
                          final isActive = currentIcons.contains(entry.key);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                style: isActive
                                    ? IconButton.styleFrom(
                                        backgroundColor: AppColors.white
                                            .withValues(alpha: .2),
                                      )
                                    : null,
                                icon: FaIcon(
                                  entry.key,
                                  color: isActive
                                      ? AppColors.green
                                      : AppColors.white,
                                ),
                                onPressed: () => Navigator.pop(
                                  context,
                                  (!isActive, entry.key),
                                ),
                              ),
                              Text(
                                entry.value,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
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
