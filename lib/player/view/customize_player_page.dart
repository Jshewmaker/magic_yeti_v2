import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/widgets/select_commander_widget.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

class CustomizePlayerPage extends StatelessWidget {
  const CustomizePlayerPage({
    required this.playerId,
    super.key,
  });
  final String playerId;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerCustomizationBloc(
        scryfallRepository: context.read<ScryfallRepository>(),
      ),
      child: CustomizePlayerView(playerId: playerId),
    );
  }
}

class CustomizePlayerView extends StatelessWidget {
  const CustomizePlayerView({
    required this.playerId,
    super.key,
  });
  final String playerId;
  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerRepository>().getPlayerById(playerId);
    final textController = TextEditingController(text: player.name);
    const width = 600.0;
    const height = 300.0;

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxlg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
              builder: (context, state) {
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: width,
                        height: height,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20),
                          ),
                          child: Image.network(
                            state.commander?.imageUrl.isNotEmpty ?? false
                                ? state.commander!.imageUrl
                                : player.commander.imageUrl,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              decoration: BoxDecoration(
                                color:
                                    Color(player.color).withValues(alpha: .8),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onEditingComplete: () =>
                                  context.read<PlayerCustomizationBloc>().add(
                                        UpdatePlayerName(
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
                          const SizedBox(width: AppSpacing.sm),
                          ElevatedButton(
                            onPressed: () {
                              final card = state.cardList!.data.first;
                              context.read<PlayerCustomizationBloc>().add(
                                    UpdatePlayerCommander(
                                      commander: Commander(
                                        name: card.name,
                                        artist: card.artist,
                                        colors: card.colors ?? [],
                                        cardType: card.typeLine,
                                        imageUrl: card.imageUris?.normal ?? '',
                                        manaCost: card.manaCost ?? '',
                                        oracleText: card.oracleText ?? '',
                                        power: card.power,
                                        toughness: card.toughness,
                                      ),
                                    ),
                                  );

                              context.read<PlayerBloc>().add(
                                    UpdatePlayerInfoEvent(
                                      playerName: textController.text,
                                      commander: state.commander,
                                      playerId: playerId,
                                    ),
                                  );

                              Navigator.pop(context);
                            },
                            style: ButtonStyle(
                              shape: WidgetStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.xxlg),
            SelectCommanderWidget(
              player: player,
            ),
          ],
        ),
      ),
    );
  }
}
