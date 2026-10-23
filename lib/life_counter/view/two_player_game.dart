import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';

/// Game layout for 1v1 formats (Standard, Modern, and so on).
///
/// Built for a phone laid flat between two players: each player gets half of
/// the screen, the top half turned to face the player across the table, with
/// the game controls in a bar between them. There is no commander damage.
///
/// The player areas run to the edges of the screen. Only the tracker drawers
/// stay inside the safe area, clear of the notch and the home indicator.
class TwoPlayerGame extends StatelessWidget {
  const TwoPlayerGame({super.key});

  static const _innerRadius = Radius.circular(20);

  @override
  Widget build(BuildContext context) {
    final playerList = context.read<GameBloc>().state.playerList;
    final isPhone = DeviceInfoProvider.of(context).isPhone;
    final safeArea = MediaQuery.paddingOf(context);

    return OrientationLock(
      // The top and bottom halves only work in portrait on a phone. A tablet
      // has room for them either way.
      orientations: isPhone
          ? const [DeviceOrientation.portraitUp]
          : const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Column(
            children: [
              PlayerTile(
                playerId: playerList[1].id,
                rotate: true,
                leftSideTracker: true,
                // Only the corners that face the control bar are rounded.
                borderRadius: const BorderRadius.vertical(
                  bottom: _innerRadius,
                ),
                fitLifeToTile: true,
                trackerPadding: EdgeInsets.only(top: safeArea.top),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: CenterControlColumn(
                  onPressed: null,
                  direction: Axis.horizontal,
                ),
              ),
              PlayerTile(
                playerId: playerList[0].id,
                rotate: false,
                leftSideTracker: true,
                borderRadius: const BorderRadius.vertical(
                  top: _innerRadius,
                ),
                fitLifeToTile: true,
                trackerPadding: EdgeInsets.only(bottom: safeArea.bottom),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
