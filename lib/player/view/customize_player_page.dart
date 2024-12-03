import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/repository/player_repository.dart';
import 'package:magic_yeti/player/widgets/select_commander_widget.dart';

class CustomizePlayerPage extends StatelessWidget {
  const CustomizePlayerPage({
    required this.playerId,
    super.key,
  });
  final int playerId;
  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerRepository>().getPlayerById(playerId);
    final textController = TextEditingController(text: player?.name);
    const width = 400.0;
    const height = 300.0;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxlg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            BlocBuilder<PlayerBloc, PlayerState>(
              builder: (context, state) {
                return Expanded(
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            height: height,
                            width: width,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: width,
                        child: TextField(
                          onEditingComplete: () =>
                              context.read<PlayerBloc>().add(
                                    UpdatePlayerInfoEvent(
                                      playerName: textController.text,
                                      playerId: playerId,
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
                                  UpdatePlayerInfoEvent(
                                    playerName: textController.text,
                                    playerId: playerId,
                                  ),
                                );
                            context.read<PlayerBloc>().add(PlayerEventReset());
                            Navigator.pop(context);
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
