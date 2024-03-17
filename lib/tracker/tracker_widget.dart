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
    required this.player,
    super.key,
  });

  final bool rotate;
  final int player;

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
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.transparent.withOpacity(.4),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: ListView(
          children: [
            ...players.map(
              (player) => Column(
                children: [
                  CommanderDamageTracker(
                    imageUrl: player.picture,
                    color: Color(player.color).withOpacity(1),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            ...counterList.map(
              (icon) => Dismissible(
                onDismissed: (detials) => setState(() {
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
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Please Select A Counter.',
            style: TextStyle(color: AppColors.white),
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                Navigator.pop(context, FontAwesomeIcons.droplet);
              },
              icon: const Icon(
                FontAwesomeIcons.droplet,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context, FontAwesomeIcons.skullCrossbones);
              },
              icon: const Icon(
                FontAwesomeIcons.skullCrossbones,
              ),
            ),
          ],
        );
      },
    );
  }
}
