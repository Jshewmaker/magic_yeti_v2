import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: _PlayerColumn(
              topPlayerId: playerList[3].id,
              bottomPlayerId: playerList[1].id,
            ),
          ),
          const CenterControlColumn(),
          Expanded(
            child: _PlayerColumn(
              topPlayerId: playerList[2].id,
              bottomPlayerId: playerList[0].id,
              alignment: Alignment.centerRight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Represents a vertical column containing two player sections.
/// Manages the layout of two players stacked vertically with appropriate spacing.
/// [topPlayerId] and [bottomPlayerId] identify the players in this column.
/// Optional [alignment] parameter allows customizing the alignment of player sections.
class _PlayerColumn extends StatelessWidget {
  const _PlayerColumn({
    required this.topPlayerId,
    required this.bottomPlayerId,
    this.alignment,
  });

  final String topPlayerId;
  final String bottomPlayerId;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _PlayerSection(
            playerId: topPlayerId,
            rotate: true,
            alignment: alignment,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: _PlayerSection(
            playerId: bottomPlayerId,
            rotate: false,
            alignment: alignment,
          ),
        ),
      ],
    );
  }
}

/// Individual player section containing life counter and tracker widgets.
/// Combines LifeCounterWidget and TrackerWidgets for a single player.
/// [playerId] identifies the player
/// [rotate] determines if the section should be rotated for proper orientation
/// [alignment] allows customizing the stack alignment of components
class _PlayerSection extends StatelessWidget {
  const _PlayerSection({
    required this.playerId,
    required this.rotate,
    this.alignment,
  });

  final String playerId;
  final bool rotate;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc(
        playerRepository: context.read<PlayerRepository>(),
        playerId: playerId,
      ),
      child: Stack(
        alignment: alignment ?? Alignment.topLeft,
        children: [
          LifeCounterWidget(
            rotate: rotate,
          ),
          TrackerWidgets(
            rotate: !rotate,
            playerId: playerId,
          ),
        ],
      ),
    );
  }
}
