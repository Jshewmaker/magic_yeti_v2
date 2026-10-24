import 'package:flutter/material.dart';
import 'package:magic_yeti/game_tags/game_tag.dart';
import 'package:magic_yeti/game_tags/game_tag_l10n.dart';
import 'package:magic_yeti/game_tags/widgets/tag_pill.dart';
import 'package:magic_yeti/l10n/l10n.dart';

/// Every tag group for [scope], each as a label over a wrap of pills.
///
/// Stateless: [selectedIds] comes from a bloc, and [onToggle] sends the
/// tapped tag back to it. Exclusive tags are resolved by
/// [GameTag.toggleIn], not here.
class GameTagPicker extends StatelessWidget {
  const GameTagPicker({
    required this.scope,
    required this.selectedIds,
    required this.onToggle,
    this.palette = TagPillPalette.app,
    super.key,
  });

  final GameTagScope scope;
  final List<String> selectedIds;
  final ValueChanged<GameTag> onToggle;
  final TagPillPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = GameTagGroup.forScope(scope);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, group) in groups.indexed) ...[
          if (index > 0) const SizedBox(height: 14),
          Text(
            group.label(l10n),
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in group.tags)
                TagPill(
                  key: ValueKey('tag_pill_${tag.id}'),
                  label: tag.label(l10n),
                  tooltip: tag.tooltip(l10n),
                  selected: selectedIds.contains(tag.id),
                  palette: palette,
                  onTap: () => onToggle(tag),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The known tags in [ids] as small read-only pills on one wrap.
class TagPillSummary extends StatelessWidget {
  const TagPillSummary({
    required this.ids,
    this.dense = true,
    this.palette = TagPillPalette.app,
    super.key,
  });

  final List<String> ids;
  final bool dense;
  final TagPillPalette palette;

  @override
  Widget build(BuildContext context) {
    final tags = GameTag.fromIds(ids);
    if (tags.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final tag in tags)
          TagPill(
            label: tag.label(l10n),
            selected: true,
            dense: dense,
            palette: palette,
          ),
      ],
    );
  }
}
