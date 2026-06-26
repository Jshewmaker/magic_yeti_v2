import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/utils/commander_mapper.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/widgets/commander_card.dart';
import 'package:magic_yeti/player/view/widgets/commander_search_bar.dart';
import 'package:player_repository/player_repository.dart';

enum _PickerTab { favorites, recent, search }

class CommanderPickerPanel extends StatefulWidget {
  const CommanderPickerPanel({required this.searchController, super.key});

  final TextEditingController searchController;

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
        final tab = _tab ?? _defaultTab(state);

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              if (state.commander != null &&
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
                  selectingPartner: state.selectingSecondCard,
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
        commanders =
            (state.magicCardList ?? []).map(magicCardToCommander).toList();
    }

    if (state.status == PlayerCustomizationStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }
    if (commanders.isEmpty) {
      return Center(
        child: Text(
          tab == _PickerTab.search
              ? 'Search for a commander above'
              : 'Nothing here yet — try Search',
          style: const TextStyle(color: AppColors.neutral60),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.72,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: commanders.length,
      itemBuilder: (context, index) {
        final commander = commanders[index];
        final selected = state.commander != null &&
            _id(state.commander!) == _id(commander);
        return CommanderCard(
          commander: commander,
          isFavorite: state.favoriteIds.contains(_id(commander)),
          isSelected: selected,
          onTap: () => _select(context, commander),
          onToggleFavorite: () => context
              .read<PlayerCustomizationBloc>()
              .add(CommanderFavoriteToggled(commander)),
        );
      },
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
          const Icon(Icons.people_outline,
              color: AppColors.tertiary, size: 18),
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
            onPressed: () => context
                .read<PlayerCustomizationBloc>()
                .add(const StartSelectingSecondCard()),
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
            onPressed: () => context
                .read<PlayerCustomizationBloc>()
                .add(const CancelSelectingSecondCard()),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
