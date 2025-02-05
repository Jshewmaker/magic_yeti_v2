import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
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

class CustomizePlayerView extends StatefulWidget {
  const CustomizePlayerView({
    required this.playerId,
    super.key,
  });
  final String playerId;

  @override
  State<CustomizePlayerView> createState() => _CustomizePlayerViewState();
}

class _CustomizePlayerViewState extends State<CustomizePlayerView> {
  final rotationController = ValueNotifier<bool>(false);

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    rotationController.dispose();
    super.dispose();
  }

  void toggleRotation() {
    final newRotated = !rotationController.value;
    rotationController.value = newRotated;
    SystemChrome.setPreferredOrientations([
      newRotated
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final player =
        context.read<PlayerRepository>().getPlayerById(widget.playerId);
    context.read<PlayerCustomizationBloc>().add(
          UpdateAccountOwnership(
            isOwner: context.read<PlayerBloc>().state.player.firebaseId != null,
          ),
        );
    final textController = TextEditingController(text: player.name);
    final scrollController = ScrollController();

    return ValueListenableBuilder<bool>(
      valueListenable: rotationController,
      builder: (context, isRotated, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.screen_rotation),
                onPressed: toggleRotation,
              ),
            ],
          ),
          body: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxlg),
              child: BlocBuilder<PlayerCustomizationBloc,
                  PlayerCustomizationState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 200, // Adjust this height as needed
                        child: Row(
                          children: [
                            CommanderImageWidget(
                              imageUrl: (state.commander?.imageUrl.isNotEmpty ??
                                      false)
                                  ? state.commander?.imageUrl ?? ''
                                  : player.commander?.imageUrl ?? '',
                              partnerImageUrl:
                                  (state.partner?.imageUrl.isNotEmpty ?? false)
                                      ? state.partner?.imageUrl
                                      : player.partner?.imageUrl,
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
                                              partner: state.hasPartner
                                                  ? state.partner
                                                  : null,
                                              playerId: widget.playerId,
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
      },
    );
  }
}
