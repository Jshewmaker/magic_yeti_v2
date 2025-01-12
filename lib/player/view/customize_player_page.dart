import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/widgets/account_ownership_widget.dart';
import 'package:magic_yeti/player/widgets/commander_image_widget.dart';
import 'package:magic_yeti/player/widgets/player_name_input_widget.dart';
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
    context.read<PlayerCustomizationBloc>().add(
          UpdateAccountOwnership(
              isOwner:
                  context.read<PlayerBloc>().state.player.firebaseId != null),
        );
    final textController = TextEditingController(text: player.name);
    final scrollController = ScrollController();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxlg),
          child: BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 200, // Adjust this height as needed
                    child: Row(
                      children: [
                        CommanderImageWidget(
                          imageUrl:
                              state.commander?.imageUrl.isNotEmpty ?? false
                                  ? state.commander!.imageUrl
                                  : player.commander.imageUrl,
                          playerColor: player.color,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PlayerNameInputWidget(
                                textController: textController,
                                onSavePressed: () {
                                  context.read<PlayerBloc>().add(
                                        UpdatePlayerInfoEvent(
                                          playerName: textController.text,
                                          commander: state.commander,
                                          playerId: playerId,
                                          firebaseId: state.isAccountOwner
                                              ? context
                                                  .read<AppBloc>()
                                                  .state
                                                  .user
                                                  .id
                                              : null,
                                        ),
                                      );
                                  Navigator.pop(context);
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AccountOwnershipWidget(
                                isAccountOwner: state.isAccountOwner,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SelectCommanderWidget(
                    player: player,
                    scrollController: scrollController,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
