import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';

/// Main view widget for the four-player game layout.
/// Arranges players in a 2x2 grid with central controls.
@visibleForTesting
class FourPlayerGame extends StatefulWidget {
  const FourPlayerGame({super.key});

  @override
  State<FourPlayerGame> createState() => _FourPlayerGameState();
}

class _FourPlayerGameState extends State<FourPlayerGame> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]),
    );
  }

  void _toggleExpanded() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(
        child: Scaffold(
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
                            PlayerTile(
                              playerId: playerList[2].id,
                              rotate: true,
                              leftSideTracker: true,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            PlayerTile(
                              playerId: playerList[1].id,
                              rotate: false,
                              leftSideTracker: true,
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
                            PlayerTile(
                              playerId: playerList[3].id,
                              rotate: true,
                              leftSideTracker: false,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            PlayerTile(
                              playerId: playerList[0].id,
                              rotate: false,
                              leftSideTracker: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!_isExpanded)
                    _CollapsedMenuButton(onTap: _toggleExpanded),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CollapsedMenuButton extends StatelessWidget {
  const _CollapsedMenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: onTap,
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
    );
  }
}
