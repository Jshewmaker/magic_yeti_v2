import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player_settings/bloc/player_settings_bloc.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

class SelectCommanderWidget extends StatelessWidget {
  const SelectCommanderWidget({required this.player, super.key});
  final Player player;
  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlayerSettingsBloc>(
      create: (_) => PlayerSettingsBloc(
        scryfallRepository: context.read<ScryfallRepository>(),
      ),
      child: PlayerSettingsView(
        player: player,
      ),
    );
  }
}

class PlayerSettingsView extends StatefulWidget {
  const PlayerSettingsView({required this.player, super.key});
  final Player player;
  @override
  State<PlayerSettingsView> createState() => _PlayerSettingsViewState();
}

class _PlayerSettingsViewState extends State<PlayerSettingsView> {
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<PlayerSettingsBloc, PlayerSettingsState>(
      builder: (context, state) {
        if (state is PlayerSettingsLoadSuccess) {
          return Expanded(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 50),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(l10n.searchButtonText),
                        onPressed: () => context.read<PlayerSettingsBloc>().add(
                              PlayerSettingsCardRequested(
                                textController.text,
                              ),
                            ),
                      ),
                    ),
                  ),
                  controller: textController,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.cardList.data.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => context.read<PlayerBloc>().add(
                              UpdateCommanderEvent(
                                pictureUrl: state
                                    .cardList.data[index].imageUris!.artCrop,
                                playerNumber: widget.player.playerNumber,
                              ),
                            ),
                        child: Row(
                          children: [
                            Image.network(
                              state.cardList.data[index].imageUris!.large,
                              scale: 4,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.cardList.data[index].name,
                                  style: const TextStyle(fontSize: 36)
                                      .copyWith(color: AppColors.white),
                                ),
                                Text(
                                  state.cardList.data[index].setName,
                                  style: const TextStyle(fontSize: 24)
                                      .copyWith(color: AppColors.white),
                                ),
                                Text(
                                  state.cardList.data[index].artist ?? '',
                                  style: const TextStyle(fontSize: 24)
                                      .copyWith(color: AppColors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 50),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(l10n.searchButtonText),
                onPressed: () => context.read<PlayerSettingsBloc>().add(
                      PlayerSettingsCardRequested(
                        textController.text,
                      ),
                    ),
              ),
            ),
          ),
          controller: textController,
        );
      },
    );
  }
}
