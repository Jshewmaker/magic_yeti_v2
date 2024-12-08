import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/tracker/tracker.dart';

class TrackerWidgets extends StatefulWidget {
  const TrackerWidgets({
    required this.rotate,
    required this.playerId,
    super.key,
  });

  final bool rotate;

  /// Player who owns the tracker.
  final String playerId;

  @override
  State<TrackerWidgets> createState() => _TrackerWidgetsState();
}

class _TrackerWidgetsState extends State<TrackerWidgets> {
  final counterList = <IconData>[];

  @override
  Widget build(BuildContext context) {
    final players = context.watch<GameBloc>().state.playerList;
    return RotatedBox(
      quarterTurns: widget.rotate ? 0 : 2,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.transparent.withOpacity(.8),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: ListView(
          children: [
            ...players.map(
              (player) => Column(
                children: [
                  CommanderDamageTracker(
                    color: player.color,
                    imageUrl: player.picture,
                    playerId: widget.playerId,
                    commanderPlayerId: player.id,
                  ),
                  // const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            ...counterList.map(
              (icon) => Dismissible(
                onDismissed: (_) => setState(() {
                  counterList.remove(icon);
                }),
                key: Key('$icon'),
                child: CounterTrackerWidget(icon: Icon(icon)),
              ),
            ),
            IconButton(
              icon: const Icon(
                FontAwesomeIcons.plus,
                color: AppColors.white,
              ),
              onPressed: () async {
                final icon = await _dialogBuilder(context);
                if (!counterList.contains(icon)) {
                  setState(() {
                    counterList.add(icon!);
                  });
                }
              },
            ),
          ],
        ),
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
];
