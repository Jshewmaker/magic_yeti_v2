import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/widgets/widgets.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

class CustomizePlayerPage extends StatelessWidget {
  const CustomizePlayerPage({
    required this.playerId,
    this.isRotated = false,
    super.key,
  });

  final String playerId;
  final bool isRotated;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerCustomizationBloc(
        scryfallRepository: context.read<ScryfallRepository>(),
      ),
      child: CustomizePlayerView(playerId: playerId, isRotated: isRotated),
    );
  }
}

class CustomizePlayerView extends StatefulWidget {
  const CustomizePlayerView({
    required this.playerId,
    this.isRotated = false,
    super.key,
  });

  final String playerId;
  final bool isRotated;

  @override
  State<CustomizePlayerView> createState() => _CustomizePlayerViewState();
}

class _CustomizePlayerViewState extends State<CustomizePlayerView> {
  late final TextEditingController _nameController;
  late final TextEditingController _searchController;
  final _scrollController = ScrollController();
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final player = context.read<PlayerRepository>().getPlayerById(
      widget.playerId,
    );
    _nameController = TextEditingController(text: player.name);
    _searchController = TextEditingController();
    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        _nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _nameController.text.length,
        );
      }
    });

    final isOwner = context.read<PlayerBloc>().state.player.firebaseId != null;
    context.read<PlayerCustomizationBloc>().add(
      UpdateAccountOwnership(isOwner: isOwner),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _save(BuildContext context, PlayerCustomizationState state) {
    context.read<PlayerBloc>().add(
      UpdatePlayerInfoEvent(
        playerName: _nameController.text,
        commander: state.commander,
        partner: state.hasPartner ? state.partner : null,
        playerId: widget.playerId,
        firebaseId: state.isAccountOwner
            ? context.read<AppBloc>().state.user.id
            : null,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerRepository>().getPlayerById(
      widget.playerId,
    );

    return BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
      builder: (context, state) {
        final commander = state.commander ?? player.commander;
        final partner = state.hasPartner
            ? (state.partner ?? player.partner)
            : null;
        return RotatedBox(
          quarterTurns: widget.isRotated ? 2 : 0,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actionsPadding: const EdgeInsets.only(right: AppSpacing.lg),
              actions: [
                FilledButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                  ),
                  onPressed: () => _save(context, state),
                ),
              ],
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                CommanderHeroBanner(
                  commander: commander,
                  partner: partner,
                  playerColor: player.color,
                ),
                ColoredBox(color: AppColors.black.withValues(alpha: 0.2)),
                SafeArea(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xxxlg * 2),
                      ),
                      SliverToBoxAdapter(
                        child: PlayerNameRow(
                          textController: _nameController,
                          focusNode: _nameFocusNode,
                          showOnlyLegendary: state.showOnlyLegendary,
                          hasPartner: state.hasPartner,
                        ),
                      ),
                      if (state.hasPartner) ...[
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.xs),
                        ),
                        SliverToBoxAdapter(
                          child: CommanderSlotSelector(
                            selectingPartner: state.selectingPartner,
                            searchTextController: _searchController,
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.sm),
                      ),
                      SliverToBoxAdapter(
                        child: CommanderSearchBar(
                          textController: _searchController,
                          selectingPartner: state.selectingPartner,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.sm),
                      ),
                      CommanderCardGrid(
                        scrollController: _scrollController,
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
