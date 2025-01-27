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
  bool showOnlyLegendary = true;
  bool hasPartner = false;
  bool selectingPartner = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                  hintText: selectingPartner
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
              onPressed: () => context.read<PlayerCustomizationBloc>().add(
                    CardListRequested(
                      cardName: textController.text,
                    ),
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Switch(
              value: showOnlyLegendary,
              onChanged: (value) {
                setState(() {
                  showOnlyLegendary = value;
                });
              },
            ),
            Text(
              'Show Only Legendary Cards',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                  ),
            ),
            const Spacer(),
            Row(
              children: [
                Checkbox(
                  value: hasPartner,
                  onChanged: (value) {
                    setState(() {
                      hasPartner = value ?? false;
                      if (!hasPartner) {
                        selectingPartner = false;
                        // Clear partner when unchecked
                        context.read<PlayerCustomizationBloc>().add(
                              const UpdatePlayerCommander(
                                partner: null,
                              ),
                            );
                      }
                    });
                  },
                ),
                Text(
                  'Has Partner',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                      ),
                ),
              ],
            ),
          ],
        ),
        if (hasPartner) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    selectingPartner ? Colors.green : Colors.blue,
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    selectingPartner = !selectingPartner;
                    textController.clear();
                  });
                },
                child: Text(
                  selectingPartner
                      ? 'Selecting Partner'
                      : 'Select Main Commander',
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
          builder: (context, state) {
            if (state.status == PlayerCustomizationStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }
            if (state.status == PlayerCustomizationStatus.success) {
              final filteredCards = showOnlyLegendary
                  ? state.cardList?.data
                      .where(
                        (card) =>
                            card.typeLine.toLowerCase().contains('legend'),
                      )
                      .toList()
                  : state.cardList?.data;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.sm),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: AppSpacing.xs,
                  mainAxisSpacing: AppSpacing.xs,
                ),
                itemCount: filteredCards?.length,
                itemBuilder: (context, index) {
                  final card = filteredCards?[index];
                  return GestureDetector(
                    onTap: () {
                      if (selectingPartner) {
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
              );
            }
            return const SizedBox(
              height: 400,
            );
          },
        ),
      ],
    );
  }
}
