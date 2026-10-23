import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game_tags/game_tags.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';

/// The saved tags of [game]: the game tags, then each tagged player.
class MatchTagsWidget extends StatelessWidget {
  const MatchTagsWidget({required this.game, super.key});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gameTags = GameTag.fromIds(game.tags);
    final taggedPlayers = game.players
        .where((player) => GameTag.fromIds(player.tags).isNotEmpty)
        .toList();
    final hasTags = gameTags.isNotEmpty || taggedPlayers.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.gameTagsHeading,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            if (!hasTags)
              Text(
                l10n.noTagsLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral60),
              ),
            if (gameTags.isNotEmpty)
              TagPillSummary(ids: game.tags, dense: false),
            for (final player in taggedPlayers) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                player.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              TagPillSummary(ids: player.tags),
            ],
          ],
        ),
      ),
    );
  }
}

/// The game tag pills while a match is being edited.
class MatchEditGameTags extends StatelessWidget {
  const MatchEditGameTags({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.gameTagsHeading,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<MatchEditCubit, MatchEditState>(
              buildWhen: (previous, current) =>
                  previous.draftGameTags != current.draftGameTags,
              builder: (context, state) => GameTagPicker(
                scope: GameTagScope.game,
                selectedIds: state.draftGameTags,
                onToggle: context.read<MatchEditCubit>().toggleGameTag,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the sheet that edits the draft tags of the player with [playerId].
Future<void> showMatchEditPlayerTagsSheet(
  BuildContext context, {
  required String playerId,
}) {
  final cubit = context.read<MatchEditCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => BlocBuilder<MatchEditCubit, MatchEditState>(
      bloc: cubit,
      builder: (context, state) {
        final player = state.draftPlayers.firstWhere((p) => p.id == playerId);
        return PlayerTagsSheet(
          playerName: player.name,
          selectedIds: player.tags,
          onToggle: (tag) => cubit.togglePlayerTag(playerId, tag),
        );
      },
    ),
  );
}
