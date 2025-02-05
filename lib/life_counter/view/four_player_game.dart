import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/tracker/tracker.dart';
import 'package:player_repository/player_repository.dart';

/// Main view widget for the four-player game layout.
/// Arranges players in a 2x2 grid with central controls.
/// Uses BLoC pattern for state management and game logic.
@visibleForTesting
class FourPlayerGame extends StatelessWidget {
  const FourPlayerGame({super.key});

  @override
  Widget build(BuildContext context) {
    final playerList = context.read<GameBloc>().state.playerList;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LayoutBuilder(
        builder: (context, constraints) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
          ]);
          return Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      LeftPlayer(
                        playerId: playerList[2].id,
                        rotate: true,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      LeftPlayer(
                        playerId: playerList[1].id,
                        rotate: false,
                      ),
                    ],
                  ),
                ),
                const CenterControlColumn(),
                Expanded(
                  child: Column(
                    children: [
                      RightPlayer(
                        playerId: playerList[3].id,
                        rotate: true,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      RightPlayer(
                        playerId: playerList[0].id,
                        rotate: false,
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class LeftPlayer extends StatelessWidget {
  const LeftPlayer({required this.playerId, required this.rotate, super.key});
  final String playerId;
  final bool rotate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc(
        playerRepository: context.read<PlayerRepository>(),
        playerId: playerId,
      ),
      child: Expanded(
        child: SizedBox.expand(
          child: Row(
            children: [
              Flexible(
                child: TrackerWidgets(
                  rotate: !rotate,
                  playerId: playerId,
                  leftSideTracker: true,
                ),
              ),
              Flexible(
                flex: 6,
                child: LifeCounterWidget(
                  rotate: rotate,
                  leftSideTracker: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RightPlayer extends StatelessWidget {
  const RightPlayer({required this.playerId, required this.rotate, super.key});
  final String playerId;
  final bool rotate;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc(
        playerRepository: context.read<PlayerRepository>(),
        playerId: playerId,
      ),
      child: Expanded(
        child: SizedBox.expand(
          child: Row(
            children: [
              Flexible(
                flex: 6,
                child: LifeCounterWidget(
                  rotate: rotate,
                  leftSideTracker: false,
                ),
              ),
              Flexible(
                child: TrackerWidgets(
                  rotate: !rotate,
                  playerId: playerId,
                  leftSideTracker: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
