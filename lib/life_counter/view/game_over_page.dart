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
import 'package:magic_yeti/life_counter/view/game_page.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:player_repository/player_repository.dart';

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
    return BlocProvider(
      create: (context) => GameOverBloc(
        players: context.read<PlayerRepository>().getPlayers(),
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
    final l10n = context.l10n;

    final gameModel = context.watch<GameBloc>().state.gameModel;
    if (gameModel == null) return const CircularProgressIndicator();
    // Restore/Undo button (only if canRestoreGame is true)
    final canRestoreGame = context.read<PlayerRepository>().canRestoreGame;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameOverTitle),
        leading: canRestoreGame
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.read<TimerBloc>().add(const TimerStartEvent());
                  context.read<GameBloc>()
                    ..add(const GameRestoreRequested())
                    ..add(const GameResumeEvent());
                  // Optionally show a snackbar or navigate
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.gameRestoredMessage)),
                  );
                  context.go(GamePage.routePath);
                },
              )
            : null,
      ),
      body: BlocBuilder<GameOverBloc, GameOverState>(
        builder: (context, state) {
          final players = state.standings;
          final winner = players.first;

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.matchOverview,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  WinnerWidget(
                                    winner: winner,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DraggableStandingsWidget(
                                  gameOverState: state,
                                ),
                                QuestionWidget(
                                  gameOverState: state,
                                  players: players,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const ButtonsWidget(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ButtonsWidget extends StatelessWidget {
  const ButtonsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gameModel = context.watch<GameBloc>().state.gameModel;
    final gameOverState = context.watch<GameOverBloc>().state;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            height: 50,
            width: 200,
            child: ElevatedButton(
              onPressed: gameOverState.selectedPlayerId == null ||
                      gameOverState.firstPlayerId == null
                  ? null
                  : () {
                      final userId = context.read<AppBloc>().state.user.id;
                      context.read<GameOverBloc>().add(
                            SendGameOverStatsEvent(
                              gameModel: gameModel,
                              userId: userId,
                            ),
                          );

                      context.go(HomePage.routeName);
                    },
              child: Text(
                l10n.returnToHome,
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
                              gameModel: gameModel,
                              userId: context.read<AppBloc>().state.user.id,
                            ),
                          );

                      context.read<GameBloc>().add(const GameResetEvent());
                      context.read<TimerBloc>().add(const TimerResetEvent());
                      context.read<TimerBloc>().add(const TimerStartEvent());
                      context.go(GamePage.routePath);
                    },
              child: Text(
                l10n.playAgain,
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
    required this.gameOverState,
    required this.players,
    super.key,
  });

  final GameOverState gameOverState;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            Row(
              children: [
                Text(
                  l10n.accountOwner,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                const Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: Duration(milliseconds: 3000),
                  message:
                      '''We use this field to sync the data to the\ncurrent logged '''
                      '''in user's account.\nDon't worry, a game id will be generated so\nthe other players can add this game to their account!''',
                  child: Icon(Icons.info_outline),
                ),
              ],
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
    required this.gameOverState,
    super.key,
  });

  final GameOverState gameOverState;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                final player = gameOverState.standings[index];

                return AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget? child) {
                    final animValue =
                        Curves.easeInOut.transform(animation.value);

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
              },
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
    required this.winner,
    super.key,
  });

  final Player winner;

  @override
  Widget build(BuildContext context) {
    final gameDuration = context.watch<TimerBloc>().state.elapsedSeconds;
    final l10n = context.l10n;
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
              _formatDuration(gameDuration ?? 0),
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
      color: player.commander?.imageUrl.isEmpty ?? true
          ? Color(player.color)
          : null,
      key: Key('$index'),
      child: Stack(
        children: [
          Container(
            height: 100,
            decoration: (player.commander?.imageUrl.isNotEmpty ?? false)
                ? BoxDecoration(
                    image: DecorationImage(
                      alignment: Alignment.topCenter,
                      image: NetworkImage(player.commander?.imageUrl ?? ''),
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
