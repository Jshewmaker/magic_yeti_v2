import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Over'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Who went first:',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              value: firstPlayerId,
                              items: players.map((player) {
                                return DropdownMenuItem(
                                  value: player.id,
                                  child: Text(
                                    player.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  firstPlayerId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Please select account owner:',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              value: selectedPlayerId,
                              items: players.map((player) {
                                return DropdownMenuItem(
                                  value: player.id,
                                  child: Text(
                                    player.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
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
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Who went first:',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              value: firstPlayerId,
                              items: players.map((player) {
                                return DropdownMenuItem(
                                  value: player.id,
                                  child: Text(
                                    player.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  firstPlayerId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Please select account owner:',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              value: selectedPlayerId,
                              items: players.map((player) {
                                return DropdownMenuItem(
                                  value: player.id,
                                  child: Text(
                                    player.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
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
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                )
              ],
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
                      'Cancel',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Spacer(),
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
                    child: const Text('Play Again'),
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
                    child: const Text('Return to Home'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
