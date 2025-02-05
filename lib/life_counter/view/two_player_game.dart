import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/tracker/tracker.dart';
import 'package:player_repository/player_repository.dart';

class TwoPlayerGame extends StatelessWidget {
  const TwoPlayerGame({super.key});

  @override
  Widget build(BuildContext context) {
    final playerList = context.read<GameBloc>().state.playerList;
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: LayoutBuilder(
          builder: (context, constraints) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeRight,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
            return orientation == Orientation.portrait
                ? Column(
                    children: [
                      Expanded(
                        child: _PlayerSection(
                          playerId: playerList[1].id,
                          rotate: true,
                        ),
                      ),
                      const RotatedBox(
                          quarterTurns: 3,
                          child: CenterControlColumn(
                            onPressed: null,
                          )),
                      Expanded(
                        child: _PlayerSection(
                          playerId: playerList[0].id,
                          rotate: false,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _PlayerColumn(
                          topPlayerId: playerList[1].id,
                          bottomPlayerId: playerList[0].id,
                        ),
                      ),
                      const CenterControlColumn(onPressed: null),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _PlayerColumn extends StatelessWidget {
  const _PlayerColumn({
    required this.topPlayerId,
    required this.bottomPlayerId,
  });

  final String topPlayerId;
  final String bottomPlayerId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _PlayerSection(
            playerId: topPlayerId,
            rotate: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: _PlayerSection(
            playerId: bottomPlayerId,
            rotate: false,
          ),
        ),
      ],
    );
  }
}

class _PlayerSection extends StatelessWidget {
  const _PlayerSection({
    required this.playerId,
    required this.rotate,
  });

  final String playerId;
  final bool rotate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc(
        playerRepository: context.read<PlayerRepository>(),
        playerId: playerId,
      ),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          LifeCounterWidget(
            rotate: rotate,
            leftSideTracker: true,
          ),
          TrackerWidgets(
            rotate: !rotate,
            playerId: playerId,
            leftSideTracker: true,
          ),
        ],
      ),
    );
  }
}
