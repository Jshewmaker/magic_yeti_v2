import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:player_repository/player_repository.dart';

class GameOverPage extends StatefulWidget {
  const GameOverPage({super.key});

  factory GameOverPage.pageBuilder(_, __) {
    return const GameOverPage(
      key: Key('game_over_page'),
    );
  }

  static const routeName = 'game_over_page';
  static String get routePath => '/game_over_page';

  @override
  State<GameOverPage> createState() => _GameOverPageState();
}

class _GameOverPageState extends State<GameOverPage> {
  bool turnOneSolRing = false;
  String? selectedPlayerId;
  String? firstPlayerId;

  @override
  Widget build(BuildContext context) {
    final players = context.watch<GameBloc>().state.playerList;
    final gameState = context.watch<GameBloc>().state;
    final l10n = context.l10n;

    // Sort players by life total to determine standings
    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) => b.lifePoints.compareTo(a.lifePoints));

    final winner = sortedPlayers.first;
    final gameDuration = gameState.elapsedSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameOverTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ScrollableColumn(
          children: [
            // Match Overview Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.matchOverview,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Final Standings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.finalStandings,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ...sortedPlayers.asMap().entries.map((entry) {
                      final player = entry.value;
                      final rank = entry.key + 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '$rank. ',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Expanded(
                              child: Text(
                                player.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              l10n.lifePoints(player.lifePoints),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Game Details Section
            Card(
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
                    // Who went first dropdown
                    Text(
                      l10n.whoWentFirst,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      value: firstPlayerId,
                      items: players.map((player) {
                        return DropdownMenuItem(
                          value: player.id,
                          child: Text(
                            player.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          firstPlayerId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    // Account owner dropdown
                    Text(
                      l10n.accountOwner,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      value: selectedPlayerId,
                      items: players.map((player) {
                        return DropdownMenuItem(
                          value: player.id,
                          child: Text(
                            player.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedPlayerId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      context.read<GameBloc>().add(const GameResumeEvent());
                      context.pop();
                    },
                    child: Text(
                      l10n.cancel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: selectedPlayerId == null && firstPlayerId == null
                        ? null
                        : () {
                            context.read<GameBloc>().add(
                                  GameUpdatePlayerOwnershipEvent(
                                    playerId: selectedPlayerId!,
                                    firebaseId:
                                        context.read<AppBloc>().state.user.id,
                                    firstPlayerId: firstPlayerId ?? '',
                                  ),
                                );
                            context.pop();
                          },
                    child: Text(l10n.playAgain),
                  ),
                  const SizedBox(width: 32),
                  ElevatedButton(
                    onPressed: selectedPlayerId == null && firstPlayerId == null
                        ? null
                        : () {
                            context.read<GameBloc>().add(
                                  GameUpdatePlayerOwnershipEvent(
                                    playerId: selectedPlayerId!,
                                    firebaseId:
                                        context.read<AppBloc>().state.user.id,
                                    firstPlayerId: firstPlayerId ?? '',
                                  ),
                                );
                            context.go(HomePage.routeName);
                          },
                    child: Text(l10n.returnToHome),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
