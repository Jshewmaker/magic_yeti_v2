import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/life_counter/life_counter.dart';
import 'package:magic_yeti/life_counter/view/game_over_page.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  factory GamePage.pageBuilder(_, __) {
    return const GamePage(
      key: Key('game_page'),
    );
  }

  static const routeName = 'game_page';
  static String get routePath => '/game_page';

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameBloc>().state;
    final playerCount = gameState.playerList.length;
    if (gameState.playerList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocListener<GameBloc, GameState>(
      listener: (context, state) {
        if (state.status == GameStatus.finished) {
          context.go('/game_page${GameOverPage.routePath}');
        }
      },
      child: playerCount == 2 ? const TwoPlayerGame() : const FourPlayerGame(),
    );
  }
}

class _GameOverDialog extends StatefulWidget {
  @override
  State<_GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<_GameOverDialog> {
  bool turnOneSolRing = false;
  String? selectedPlayerId;
  String? firstPlayerId;

  @override
  Widget build(BuildContext context) {
    final players = context.watch<GameBloc>().state.playerList;

    return Dialog(
      alignment: Alignment.center,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.80,
        height: MediaQuery.of(context).size.height * 0.80,
        child: AlertDialog(
          actionsPadding: const EdgeInsets.only(top: 128.0),
          alignment: Alignment.topCenter,
          title: Center(
            child: Text(
              'Game Over',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SwitchListTile(
                      //   title: Text(
                      //     'Turn 1 Sol Ring',
                      //     style: Theme.of(context).textTheme.titleLarge,
                      //   ),
                      //   value: turnOneSolRing,
                      //   onChanged: (bool value) {
                      //     setState(() {
                      //       turnOneSolRing = value;
                      //     });
                      //   },
                      // ),
                      if (players.isNotEmpty) ...[
                        const SizedBox(height: 32),
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
                    ],
                  ),
                ),
                const Spacer(),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    context.read<GameBloc>().add(const GameResumeEvent());
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
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

                          Navigator.of(context).pop();
                        },
                  child: Text(
                    'Play Again',
                    // style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 16),
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
                          GoRouter.of(context).go(HomePage.routeName);
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    'Return to Home',
                    //  style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
