// lib/match_details/widgets/commander_picker.dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/utils/commander_mapper.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/match_details/bloc/commander_picker_cubit.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

typedef PickCommander = Future<Commander?> Function(
  BuildContext context, {
  required bool selectingPartner,
});

/// Opens a full-screen commander picker and resolves to the chosen [Commander],
/// or `null` if dismissed.
Future<Commander?> showCommanderPicker(
  BuildContext context, {
  required bool selectingPartner,
}) {
  final scryfallRepository = context.read<ScryfallRepository>();
  return Navigator.of(context).push<Commander>(
    MaterialPageRoute<Commander>(
      fullscreenDialog: true,
      builder: (_) => BlocProvider(
        create: (_) =>
            CommanderPickerCubit(scryfallRepository: scryfallRepository),
        child: CommanderPickerView(selectingPartner: selectingPartner),
      ),
    ),
  );
}

class CommanderPickerView extends StatefulWidget {
  const CommanderPickerView({required this.selectingPartner, super.key});

  final bool selectingPartner;

  @override
  State<CommanderPickerView> createState() => _CommanderPickerViewState();
}

class _CommanderPickerViewState extends State<CommanderPickerView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    await context.read<CommanderPickerCubit>().search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectingPartner
              ? l10n.selectPartnerTitle
              : l10n.selectCommanderTitle,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autocorrect: false,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: l10n.searchCommanderHintText,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _search,
                  child: Text(l10n.searchButtonText),
                ),
              ],
            ),
          ),
          const Expanded(child: _ResultsGrid()),
        ],
      ),
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CommanderPickerCubit, CommanderPickerState>(
      builder: (context, state) {
        switch (state.status) {
          case CommanderPickerStatus.initial:
            return const SizedBox.shrink();
          case CommanderPickerStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case CommanderPickerStatus.failure:
            return Center(child: Text(l10n.somethingWentWrong));
          case CommanderPickerStatus.success:
            if (state.cards.isEmpty) {
              return Center(child: Text(l10n.noCommanders));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 0.72,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: state.cards.length,
              itemBuilder: (context, index) {
                final card = state.cards[index];
                final imageUrl = card.imageUris?.normal ??
                    card.cardFaces?.first.imageUris?.normal ??
                    '';
                return GestureDetector(
                  key: ValueKey('commander-card-${card.id}'),
                  onTap: () =>
                      Navigator.of(context).pop(magicCardToCommander(card)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                        color: AppColors.neutral60,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                );
              },
            );
        }
      },
    );
  }
}
