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
class FourPlayerGame extends StatefulWidget {
  const FourPlayerGame({super.key});

  @override
  State<FourPlayerGame> createState() => _FourPlayerGameState();
}

class _FourPlayerGameState extends State<FourPlayerGame> {
  bool _isExpanded = true;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LayoutBuilder(
        builder: (context, constraints) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
          ]);
          return Scaffold(
            body: BlocBuilder<GameBloc, GameState>(
              buildWhen: (previous, current) =>
                  previous.playerList != current.playerList,
              builder: (context, state) {
                final playerList = state.playerList;
                return Stack(
                  children: [
                    Row(
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _isExpanded ? 50 : 2,
                          child: _isExpanded
                              ? CenterControlColumn(onPressed: _toggleExpanded)
                              : null,
                        ),
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
                        ),
                      ],
                    ),
                    if (!_isExpanded)
                      Center(
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: FloatingActionButton(
                            onPressed: _toggleExpanded,
                            backgroundColor: AppColors.primary,
                            shape: const CircleBorder(),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/icon/yeti_icon.png',
                                color: Colors.white,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
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
              SizedBox(
                width: 90,
                child: TrackerWidgets(
                  rotate: !rotate,
                  playerId: playerId,
                  leftSideTracker: true,
                ),
              ),
              Expanded(
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
              Expanded(
                child: LifeCounterWidget(
                  rotate: rotate,
                  leftSideTracker: false,
                ),
              ),
              SizedBox(
                width: 90,
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
