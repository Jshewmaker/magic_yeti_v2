import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/tracker/tracker.dart';
import 'package:player_repository/player_repository.dart';

class FourPlayerPage extends StatelessWidget {
  const FourPlayerPage({super.key});

  factory FourPlayerPage.pageBuilder(_, __) {
    return const FourPlayerPage(
      key: Key('life_counter_page'),
    );
  }

  static const routeName = 'life_counter_page';
  static String get routePath => '/life_counter_page';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Stack(
          children: [
            const FourPlayerView(),
            if (state.status == GameStatus.finished) const GameOverWidget(),
          ],
        );
      },
    );
  }
}

/// Main view widget for the four-player game layout.
/// Arranges players in a 2x2 grid with central controls.
/// Uses BLoC pattern for state management and game logic.
@visibleForTesting
class FourPlayerView extends StatelessWidget {
  const FourPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameBloc>().state;
    
    if (gameState.playerList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // For 2 player game
    if (gameState.playerList.length == 2) {
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _PlayerColumn(
                    topPlayerId: gameState.playerList[0].id,
                    bottomPlayerId: gameState.playerList[1].id,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ),
          ),
          const _CenterControlColumn(),
        ],
      );
    }

    // For 4 player game
    return Row(
      children: [
        Expanded(
          child: _PlayerColumn(
            topPlayerId: gameState.playerList[3].id,
            bottomPlayerId: gameState.playerList[1].id,
          ),
        ),
        const _CenterControlColumn(),
        Expanded(
          child: _PlayerColumn(
            topPlayerId: gameState.playerList[2].id,
            bottomPlayerId: gameState.playerList[0].id,
            alignment: Alignment.centerRight,
          ),
        ),
      ],
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

/// Central control column containing game controls and utilities.
/// Displays reset button, timer widget, and dice icon.
/// Positioned between the two player columns for easy access.
class _CenterControlColumn extends StatelessWidget {
  const _CenterControlColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(
            Icons.refresh,
            color: Colors.white,
            size: 50,
          ),
          onPressed: () => context.read<GameBloc>().add(const GameResetEvent()),
        ),
        const TimerWidget(),
        const Icon(
          FontAwesomeIcons.diceOne,
          size: 30,
        ),
      ],
    );
  }
}

/// Game over widget displayed when the game is finished.
/// Provides a "Play Again" button to reset the game.
class GameOverWidget extends StatelessWidget {
  const GameOverWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withOpacity(.5),
      child: Center(
        child: ElevatedButton(
          onPressed: () => context.read<GameBloc>().add(const GameResetEvent()),
          child: const Text('Play Again'),
        ),
      ),
    );
  }
}
