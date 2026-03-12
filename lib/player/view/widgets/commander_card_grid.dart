import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:player_repository/player_repository.dart';

/// A sliver that renders commander search results lazily as the user scrolls.
class CommanderCardGrid extends StatelessWidget {
  const CommanderCardGrid({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
      builder: (context, state) {
        if (state.selectingPartner) {
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: _PartnerSelectionBanner()),
              _buildResultSliver(state, l10n),
            ],
          );
        }
        return _buildResultSliver(state, l10n);
      },
    );
  }

  Widget _buildResultSliver(
    PlayerCustomizationState state,
    AppLocalizations l10n,
  ) {
    if (state.status == PlayerCustomizationStatus.loading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      );
    }

    if (state.status == PlayerCustomizationStatus.failure) {
      return SliverFillRemaining(
        child: Center(child: Text(l10n.somethingWentWrong)),
      );
    }

    final cards = state.magicCardList ?? [];

    if (state.status == PlayerCustomizationStatus.success && cards.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text(l10n.noCommanders)),
      );
    }

    if (state.status == PlayerCustomizationStatus.success) {
      return _CardGridSliver(
        cards: cards,
        selectingPartner: state.selectingPartner,
        scrollController: scrollController,
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}

class _PartnerSelectionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.xlg,
        AppSpacing.sm,
        AppSpacing.xlg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withAlpha(40),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.tertiary.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.tertiary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Selecting partner commander',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _CardGridSliver extends StatelessWidget {
  const _CardGridSliver({
    required this.cards,
    required this.selectingPartner,
    required this.scrollController,
  });

  final List<MagicCard> cards;
  final bool selectingPartner;
  final ScrollController scrollController;

  void _onCardTapped(BuildContext context, MagicCard card) {
    unawaited(
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    );

    final commander = Commander(
      oracleId: card.oracleId,
      name: card.name,
      typeLine: card.typeLine ?? '',
      scryFallUrl: card.scryfallUri,
      edhrecRank: card.edhrecRank,
      artist: card.artist ?? '',
      colors: card.colors ?? [],
      colorIdentity: card.colorIdentity,
      cardType: card.typeLine ?? '',
      imageUrl: card.imageUris?.artCrop ?? '',
      manaCost: card.manaCost ?? '',
      oracleText: card.oracleText ?? '',
      power: card.power,
      toughness: card.toughness,
    );

    context.read<PlayerCustomizationBloc>().add(
          selectingPartner
              ? UpdatePlayerCommander(partner: commander)
              : UpdatePlayerCommander(commander: commander),
        );
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.xlg),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.72,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final card = cards[index];
            return _CardGridItem(
              card: card,
              onTap: () => _onCardTapped(context, card),
            );
          },
          childCount: cards.length,
        ),
      ),
    );
  }
}

class _CardGridItem extends StatelessWidget {
  const _CardGridItem({
    required this.card,
    required this.onTap,
  });

  final MagicCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = card.imageUris?.normal ??
        card.cardFaces?.first.imageUris?.normal ??
        '';

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: ColoredBox(
          color: AppColors.quaternary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
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
              ColoredBox(
                color: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    card.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
