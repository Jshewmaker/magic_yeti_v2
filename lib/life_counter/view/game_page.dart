import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/life_counter.dart';

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
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => _GameOverDialog(),
          );
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

  @override
  Widget build(BuildContext context) {
    final players = context.watch<GameBloc>().state.playerList;

    return AlertDialog(
      title: const Text('Game Over'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Turn 1 Sol Ring'),
            value: turnOneSolRing,
            onChanged: (bool value) {
              setState(() {
                turnOneSolRing = value;
              });
            },
          ),
          if (players.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Please select account owner',
                border: OutlineInputBorder(),
              ),
              value: selectedPlayerId,
              items: players.map((player) {
                return DropdownMenuItem(
                  value: player.id,
                  child: Text(player.name),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedPlayerId == null
              ? null
              : () {
                  context.read<GameBloc>().add(
                        GameUpdatePlayerOwnershipEvent(
                          playerId: selectedPlayerId!,
                          firebaseId: context.read<AppBloc>().state.user.id,
                        ),
                      );

                  Navigator.of(context).pop();
                },
          child: const Text('Play Again'),
        ),
      ],
    );
  }
}
