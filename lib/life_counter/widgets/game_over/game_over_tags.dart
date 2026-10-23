import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game_tags/game_tags.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_tokens.dart';
import 'package:player_repository/player_repository.dart';

/// Tag pills in the game over colors.
const gameOverTagPalette = TagPillPalette(
  accent: GameOverTokens.accent,
  surface: GameOverTokens.surfaceRaised,
  border: GameOverTokens.border,
  text: GameOverTokens.textPrimary,
  mutedText: GameOverTokens.textSecondary,
);

/// The game tag pills. Each tap toggles the tag in [GameOverBloc].
class GameOverTagsSection extends StatelessWidget {
  const GameOverTagsSection({required this.state, super.key});

  final GameOverState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.hasSuggestedTags) ...[
          Text(
            context.l10n.gameTagsAutoHint,
            style: const TextStyle(
              color: GameOverTokens.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
        ],
        GameTagPicker(
          scope: GameTagScope.game,
          selectedIds: state.gameTags,
          palette: gameOverTagPalette,
          onToggle: (tag) =>
              context.read<GameOverBloc>().add(ToggleGameTagEvent(tag)),
        ),
      ],
    );
  }
}

/// Opens the sheet that edits the tags of the player with [playerId].
Future<void> showGameOverPlayerTagsSheet(
  BuildContext context, {
  required String playerId,
}) {
  final bloc = context.read<GameOverBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: GameOverTokens.surface,
    builder: (_) => BlocBuilder<GameOverBloc, GameOverState>(
      bloc: bloc,
      builder: (context, state) {
        final player = state.standings.firstWhere((p) => p.id == playerId);
        return PlayerTagsSheet(
          playerName: player.name,
          selectedIds: player.tags,
          palette: gameOverTagPalette,
          onToggle: (tag) =>
              bloc.add(TogglePlayerTagEvent(playerId: playerId, tag: tag)),
        );
      },
    ),
  );
}

/// Up to [maxVisible] of a player's tags on one line, then a "+N" count.
///
/// One line only, so the standings row keeps its normal height. The caller
/// picks [maxVisible] for the row width: 2 on a phone, 3 on a tablet.
class PlayerTagsLine extends StatelessWidget {
  const PlayerTagsLine({required this.player, this.maxVisible = 2, super.key});

  final Player player;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final tags = GameTag.fromIds(player.tags);
    if (tags.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final hidden = tags.length - maxVisible;
    return Row(
      children: [
        for (final tag in tags.take(maxVisible))
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TagPill(
                label: tag.label(l10n),
                selected: true,
                dense: true,
                palette: gameOverTagPalette,
              ),
            ),
          ),
        if (hidden > 0)
          Text(
            '+$hidden',
            style: const TextStyle(
              color: GameOverTokens.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
