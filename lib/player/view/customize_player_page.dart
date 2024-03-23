import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player_settings.dart';

class CustomizePlayerPage extends StatelessWidget {
  const CustomizePlayerPage({
    required this.player,
    super.key,
  });
  final Player player;

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: player.name);
    const width = 400.0;
    const height = 300.0;

    return BlocConsumer<PlayerBloc, PlayerState>(
      listener: (context, state) {
        if (state is PlayerUpdated) {
          context.read<GameBloc>().add(UpdatePlayerEvent(player: state.player));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                BlocBuilder<PlayerBloc, PlayerState>(
                  builder: (context, state) {
                    return Expanded(
                      child: Column(
                        children: [
                          if (state is PlayerUpdated)
                            Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              height: height,
                              width: width,
                              child: Image.network(
                                state.player.picture,
                                fit: BoxFit.fill,
                              ),
                            )
                          else
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
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: width,
                            child: TextField(
                              onEditingComplete: () =>
                                  context.read<PlayerBloc>().add(
                                        UpdatePlayerInfoEvent(
                                          player: player.copyWith(
                                            name: textController.text,
                                          ),
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
                          if (state is PlayerUpdated)
                            SizedBox(
                              width: width / 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<PlayerBloc>().add(
                                        UpdatePlayerInfoEvent(
                                          player: player.copyWith(
                                            name: textController.text,
                                            picture: state.player.picture,
                                          ),
                                        ),
                                      );
                                  context
                                      .read<PlayerBloc>()
                                      .add(PlayerEventReset());
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
      },
    );
  }
}
