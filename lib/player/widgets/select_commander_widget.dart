import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:player_repository/player_repository.dart';

class SelectCommanderWidget extends StatefulWidget {
  const SelectCommanderWidget({
    required this.player,
    required this.scrollController,
    super.key,
  });
  final Player player;
  final ScrollController scrollController;

  @override
  State<SelectCommanderWidget> createState() => _SelectCommanderWidgetState();
}

class _SelectCommanderWidgetState extends State<SelectCommanderWidget> {
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onSubmitted: (value) =>
                        context.read<PlayerCustomizationBloc>().add(
                              CardListRequested(
                                cardName: value,
                              ),
                            ),
                    decoration: InputDecoration(
                      hintText: state.selectingPartner
                          ? 'Search for partner commander...'
                          : l10n.searchCommanderHintText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                      ),
                    ),
                    controller: textController,
                    autocorrect: false,
                    onTap: () {
                      widget.scrollController.animateTo(
                        200,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.searchButtonText,
                    style: const TextStyle(color: AppColors.white),
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    context.read<PlayerCustomizationBloc>().add(
                          CardListRequested(
                            cardName: textController.text,
                          ),
                        );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Switch(
                  value: state.showOnlyLegendary,
                  onChanged: (value) {
                    context.read<PlayerCustomizationBloc>().add(
                          UpdateCommanderFilters(
                            showOnlyLegendary: value,
                            hasPartner: state.hasPartner,
                          ),
                        );
                  },
                ),
                Text(
                  'Show Only Legendary Cards',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                      ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: state.hasPartner,
                      onChanged: (value) {
                        context.read<PlayerCustomizationBloc>().add(
                              UpdateCommanderFilters(
                                showOnlyLegendary: state.showOnlyLegendary,
                                hasPartner: value ?? false,
                              ),
                            );
                      },
                    ),
                    Text(
                      'Has Partner',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.white,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            if (state.hasPartner) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        state.selectingPartner ? Colors.green : Colors.blue,
                      ),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    onPressed: () {
                      context.read<PlayerCustomizationBloc>().add(
                            UpdatePartnerSelection(
                              selectingPartner: !state.selectingPartner,
                            ),
                          );
                      context
                          .read<PlayerCustomizationBloc>()
                          .add(const ClearCardList());
                      textController.clear();
                    },
                    child: Text(
                      state.selectingPartner
                          ? 'Selecting Partner'
                          : 'Select Main Commander',
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (state.status == PlayerCustomizationStatus.loading) ...[
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ] else if (state.status == PlayerCustomizationStatus.success) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.sm),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: AppSpacing.xs,
                  mainAxisSpacing: AppSpacing.xs,
                ),
                itemCount: state.magicCardList?.length,
                itemBuilder: (context, index) {
                  final card = state.magicCardList?[index];
                  return GestureDetector(
                    onTap: () {
                      widget.scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                      if (state.selectingPartner) {
                        context.read<PlayerCustomizationBloc>().add(
                              UpdatePlayerCommander(
                                partner: Commander(
                                  name: card?.name ?? '',
                                  typeLine: card?.typeLine ?? '',
                                  scryFallUrl: card?.scryfallUri ?? '',
                                  edhrecRank: card?.edhrecRank,
                                  artist: card?.artist ?? '',
                                  colors: card?.colors ?? [],
                                  colorIdentity: card?.colorIdentity,
                                  cardType: card?.typeLine ?? '',
                                  imageUrl: card?.imageUris?.artCrop ?? '',
                                  manaCost: card?.manaCost ?? '',
                                  oracleText: card?.oracleText ?? '',
                                  power: card?.power,
                                  toughness: card?.toughness,
                                ),
                              ),
                            );
                      } else {
                        context.read<PlayerCustomizationBloc>().add(
                              UpdatePlayerCommander(
                                commander: Commander(
                                  name: card?.name ?? '',
                                  typeLine: card?.typeLine ?? '',
                                  scryFallUrl: card?.scryfallUri ?? '',
                                  edhrecRank: card?.edhrecRank,
                                  artist: card?.artist ?? '',
                                  colors: card?.colors ?? [],
                                  colorIdentity: card?.colorIdentity,
                                  cardType: card?.typeLine ?? '',
                                  imageUrl: card?.imageUris?.artCrop ?? '',
                                  manaCost: card?.manaCost ?? '',
                                  oracleText: card?.oracleText ?? '',
                                  power: card?.power,
                                  toughness: card?.toughness,
                                ),
                              ),
                            );
                      }
                    },
                    child: Card(
                      elevation: 0,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              card?.imageUris?.normal ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const ColoredBox(
                                color: AppColors.neutral60,
                                child: Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            child: Text(
                              card?.artist ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.white,
                                  ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            if (state.status == PlayerCustomizationStatus.failure) ...[
              SizedBox(
                height: 400,
                child: Center(
                  child: Text(l10n.somethingWentWrong),
                ),
              ),
            ],
            if (state.magicCardList?.isEmpty ?? false) ...[
              SizedBox(
                height: 400,
                child: Center(
                  child: Text(l10n.noCommanders),
                ),
              ),
            ] else ...[
              const SizedBox(
                height: 400,
                child: Center(),
              ),
            ],
          ],
        );
      },
    );
  }
}
