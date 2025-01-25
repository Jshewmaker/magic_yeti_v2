import 'dart:ui';

import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:player_repository/models/player.dart';

class GameOverPage extends StatelessWidget {
  const GameOverPage({super.key});

  factory GameOverPage.pageBuilder(_, __) {
    return const GameOverPage(
      key: Key('game_over_page'),
    );
  }

  static const routeName = 'game_over_page';
  static String get routePath => '/game_over_page';

  @override
  Widget build(BuildContext context) {
    final players = context.watch<GameBloc>().state.playerList;
    return BlocProvider(
      create: (context) => GameOverBloc(
        players: players,
        firebaseDatabaseRepository: context.read<FirebaseDatabaseRepository>(),
      ),
      child: const GameOverView(),
    );
  }
}

class GameOverView extends StatelessWidget {
  const GameOverView({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameBloc>().state;
    final l10n = context.l10n;
    final gameOverState = context.watch<GameOverBloc>().state;
    final players = gameState.playerList;

    final winner = gameOverState.standings.first;
    final gameDuration = gameState.elapsedSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameOverTitle),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.matchOverview,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      WinnerWidget(
                        l10n: l10n,
                        winner: winner,
                        gameDuration: gameDuration,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DraggableStandingsWidget(
                      l10n: l10n,
                      gameOverState: gameOverState,
                    ),
                    QuestionWidget(
                      l10n: l10n,
                      gameOverState: gameOverState,
                      players: players,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ButtonsWidget(
                  l10n: l10n,
                  gameOverState: gameOverState,
                  gameState: gameState,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class ButtonsWidget extends StatelessWidget {
  const ButtonsWidget({
    required this.l10n,
    required this.gameOverState,
    required this.gameState,
    super.key,
  });

  final AppLocalizations l10n;
  final GameOverState gameOverState;
  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              context.pop();
            },
            child: Text(
              l10n.cancel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 50,
            width: 200,
            child: ElevatedButton(
              onPressed: gameOverState.selectedPlayerId == null ||
                      gameOverState.firstPlayerId == null
                  ? null
                  : () {
                      context.read<GameOverBloc>().add(
                            SendGameOverStatsEvent(
                              gameModel: gameState.gameModel,
                              userId: context.read<AppBloc>().state.user.id,
                            ),
                          );

                      context.go(HomePage.routeName);
                    },
              child: Text(
                l10n.returnToHome,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ),
          const SizedBox(width: 64),
          SizedBox(
            height: 50,
            width: 200,
            child: ElevatedButton(
              onPressed: gameOverState.selectedPlayerId == null ||
                      gameOverState.firstPlayerId == null
                  ? null
                  : () {
                      context.read<GameOverBloc>().add(
                            SendGameOverStatsEvent(
                              gameModel: gameState.gameModel,
                              userId: context.read<AppBloc>().state.user.id,
                            ),
                          );
                      context.read<GameBloc>().add(const GameResetEvent());
                      context.pop();
                    },
              child: Text(
                l10n.playAgain,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionWidget extends StatelessWidget {
  const QuestionWidget({
    required this.l10n,
    required this.gameOverState,
    required this.players,
    super.key,
  });

  final AppLocalizations l10n;
  final GameOverState gameOverState;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.gameDetails,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.whoWentFirst,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              value: gameOverState.firstPlayerId,
              items: players.map((player) {
                return DropdownMenuItem(
                  value: player.id,
                  child: Text(
                    player.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                context.read<GameOverBloc>().add(UpdateFirstPlayerEvent(value));
              },
            ),
            const SizedBox(height: 24),
            Text(
              l10n.accountOwner,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              value: gameOverState.selectedPlayerId,
              items: players.map((player) {
                return DropdownMenuItem(
                  value: player.id,
                  child: Text(
                    player.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                context
                    .read<GameOverBloc>()
                    .add(UpdateSelectedPlayerEvent(value));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DraggableStandingsWidget extends StatelessWidget {
  const DraggableStandingsWidget({
    required this.l10n,
    required this.gameOverState,
    super.key,
  });

  final AppLocalizations l10n;
  final GameOverState gameOverState;

  @override
  Widget build(BuildContext context) {
    Widget proxyDecorator(
      Widget child,
      int index,
      Animation<double> animation,
    ) {
      final player = gameOverState.standings[index];

      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final animValue = Curves.easeInOut.transform(animation.value);

          final scale = lerpDouble(1, 1.1, animValue)!;
          return Transform.scale(
            scale: scale,
            child: StandingsWidget(
              key: Key('$index'),
              player: player,
              index: index,
            ),
          );
        },
        child: child,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.finalStandings,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 8),
              const Tooltip(
                message: 'Drag to reorder',
                waitDuration: Duration(milliseconds: 100),
                child: Icon(Icons.drag_indicator),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: ReorderableListView.builder(
              shrinkWrap: true,
              proxyDecorator: proxyDecorator,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gameOverState.standings.length,
              onReorder: (oldIndex, newIndex) {
                context.read<GameOverBloc>().add(
                      UpdateStandingsEvent(
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                      ),
                    );
              },
              itemBuilder: (context, index) {
                final player = gameOverState.standings[index];

                return StandingsWidget(
                  key: Key('$index'),
                  player: player,
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WinnerWidget extends StatelessWidget {
  const WinnerWidget({
    super.key,
    required this.l10n,
    required this.winner,
    required this.gameDuration,
  });

  final AppLocalizations l10n;
  final Player winner;
  final int gameDuration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.winner,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                winner.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.white,
                    ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l10n.gameDuration,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              _formatDuration(gameDuration),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ],
    );
  }
}

class StandingsWidget extends StatelessWidget {
  const StandingsWidget({
    required this.player,
    required this.index,
    super.key,
  });

  final Player player;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: player.commander.imageUrl.isEmpty ? Color(player.color) : null,
      key: Key('$index'),
      child: Stack(
        children: [
          Container(
            height: 100,
            decoration: player.commander.imageUrl.isNotEmpty
                ? BoxDecoration(
                    image: DecorationImage(
                      alignment: Alignment.topCenter,
                      image: NetworkImage(player.commander.imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.6),
                        BlendMode.darken,
                      ),
                    ),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      player.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.drag_handle,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours}h ${minutes}m';
}
