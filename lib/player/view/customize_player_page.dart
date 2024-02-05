import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app_router/app_router.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player_settings.dart';

class CustomizePlayerPage extends StatelessWidget {
  const CustomizePlayerPage({
    required this.playerNumber,
    super.key,
  });
  final String playerNumber;

  @override
  Widget build(BuildContext context) {
    final player =
        context.watch<PlayerBloc>().state.playerList[int.parse(playerNumber)];
    final textController = TextEditingController(text: player.name);
    const width = 400.0;
    const height = 300.0;
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    height: height,
                    width: width,
                    child: Image.network(
                      player.picture,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20),
                          ),
                          color: Color(player.color).withOpacity(1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: width,
                    child: TextField(
                      onEditingComplete: () => context.read<PlayerBloc>().add(
                            UpdatePlayerNameEvent(
                              playerNumber: player.playerNumber,
                              name: textController.text,
                            ),
                          ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      controller: textController,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: width / 2,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<PlayerBloc>().add(
                              UpdatePlayerNameEvent(
                                name: textController.text,
                                playerNumber: player.playerNumber,
                              ),
                            );
                        AppRouter.of(context).goRouter.pop();
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  SelectCommanderWidget(
                    player: player,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
