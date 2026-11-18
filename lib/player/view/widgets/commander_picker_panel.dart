import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/utils/commander_mapper.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/widgets/commander_card.dart';
import 'package:magic_yeti/player/view/widgets/commander_search_bar.dart';
import 'package:player_repository/player_repository.dart';

enum _PickerTab { favorites, recent, search }

class CommanderPickerPanel extends StatefulWidget {
  const CommanderPickerPanel({
    required this.searchController,
    this.isCommanderGame = true,
    super.key,
  });

  final TextEditingController searchController;

  /// When false, the panel is a plain card search: no favorites, recents,
  /// partners, or backgrounds, which are all Commander concepts.
  final bool isCommanderGame;

  @override
  State<CommanderPickerPanel> createState() => _CommanderPickerPanelState();
}

class _CommanderPickerPanelState extends State<CommanderPickerPanel> {
  _PickerTab? _tab;

  _PickerTab _defaultTab(PlayerCustomizationState s) {
    if (s.favorites.isNotEmpty) return _PickerTab.favorites;
    if (s.recents.isNotEmpty) return _PickerTab.recent;
    return _PickerTab.search;
  }

  String _id(Commander c) => c.oracleId ?? c.name;

  void _select(BuildContext context, Commander commander) {
    final bloc = context.read<PlayerCustomizationBloc>();
    if (bloc.state.selectingSecondCard) {
      bloc.add(SecondCardSelected(commander));
    } else {
      bloc.add(CommanderSelected(commander));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
      builder: (context, state) {
        final isCommanderGame = widget.isCommanderGame;
        final tab = isCommanderGame
            ? _tab ?? _defaultTab(state)
            : _PickerTab.search;

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCommanderGame)
                SegmentedButton<_PickerTab>(
                  segments: const [
                    ButtonSegment(
                      value: _PickerTab.favorites,
                      label: Text('Favorites'),
                      icon: Icon(Icons.star_border),
                    ),
                    ButtonSegment(
                      value: _PickerTab.recent,
                      label: Text('Recent'),
                      icon: Icon(Icons.history),
                    ),
                    ButtonSegment(
                      value: _PickerTab.search,
                      label: Text('Search'),
                      icon: Icon(Icons.search),
                    ),
                  ],
                  selected: {tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              const SizedBox(height: AppSpacing.sm),
              if (isCommanderGame &&
                  state.commander != null &&
                  state.availablePairing != CommanderPairing.none &&
                  !state.selectingSecondCard &&
                  state.partner == null &&
                  state.background == null)
                _SecondCardBanner(pairing: state.availablePairing),
              if (state.selectingSecondCard) const _SelectingSecondCardBanner(),
              if (tab == _PickerTab.search) ...[
                const SizedBox(height: AppSpacing.sm),
                CommanderSearchBar(
                  textController: widget.searchController,
                  hintText: isCommanderGame
                      ? null
                      : context.l10n.searchCardHintText,
                  selectingPartner: state.selectingSecondCard,
                  searchBackgrounds:
                      state.selectingSecondCard &&
                      state.availablePairing == CommanderPairing.background,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _grid(context, state, tab),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _grid(
    BuildContext context,
    PlayerCustomizationState state,
    _PickerTab tab,
  ) {
    final List<Commander> commanders;
    switch (tab) {
      case _PickerTab.favorites:
        commanders = state.favorites;
      case _PickerTab.recent:
        commanders = state.recents;
      case _PickerTab.search:
        commanders = (state.magicCardList ?? [])
            .map(magicCardToCommander)
            .toList();
    }

    if (state.status == PlayerCustomizationStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }
    if (state.status == PlayerCustomizationStatus.failure) {
      return Center(
        child: Text(
          context.l10n.somethingWentWrong,
          style: const TextStyle(color: AppColors.neutral60),
        ),
      );
    }
    if (commanders.isEmpty) {
      return Center(
        child: Text(
          !widget.isCommanderGame
              ? context.l10n.searchCardEmptyText
              : tab == _PickerTab.search
              ? 'Search for a commander above'
              : 'Nothing here yet — try Search',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.neutral60),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // Three columns on a portrait phone, where four make the cards
          // too small to read.
          crossAxisCount: constraints.maxWidth < 400 ? 3 : 4,
          childAspectRatio: 0.72,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        itemCount: commanders.length,
        itemBuilder: (context, index) {
          final commander = commanders[index];
          final selected =
              state.commander != null &&
              _id(state.commander!) == _id(commander);
          return CommanderCard(
            commander: commander,
            isFavorite: state.favoriteIds.contains(_id(commander)),
            isSelected: selected,
            onTap: () => _select(context, commander),
            // Favorites are the device's commander library, so a 1v1 deck
            // card is not added to them.
            onToggleFavorite: widget.isCommanderGame
                ? () => context.read<PlayerCustomizationBloc>().add(
                    CommanderFavoriteToggled(commander),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _SecondCardBanner extends StatelessWidget {
  const _SecondCardBanner({required this.pairing});

  final CommanderPairing pairing;

  @override
  Widget build(BuildContext context) {
    final isBackground = pairing == CommanderPairing.background;
    final label = isBackground ? 'Add background' : 'Add partner';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withAlpha(40),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.tertiary.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: AppColors.tertiary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isBackground
                  ? 'This commander can choose a Background'
                  : 'This commander can take a partner',
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => context.read<PlayerCustomizationBloc>().add(
              const StartSelectingSecondCard(),
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _SelectingSecondCardBanner extends StatelessWidget {
  const _SelectingSecondCardBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(40),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.secondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Selecting second card',
              style: TextStyle(color: AppColors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => context.read<PlayerCustomizationBloc>().add(
              const CancelSelectingSecondCard(),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
