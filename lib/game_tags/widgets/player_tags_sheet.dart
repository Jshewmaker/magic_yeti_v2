import 'package:flutter/material.dart';
import 'package:magic_yeti/game_tags/game_tag.dart';
import 'package:magic_yeti/game_tags/widgets/game_tag_picker.dart';
import 'package:magic_yeti/game_tags/widgets/tag_pill.dart';
import 'package:magic_yeti/l10n/l10n.dart';

/// The body of the bottom sheet that edits one player's tags.
///
/// Each screen wraps it in a builder for its own bloc, so [selectedIds]
/// stays live while the sheet is open.
class PlayerTagsSheet extends StatelessWidget {
  const PlayerTagsSheet({
    required this.playerName,
    required this.selectedIds,
    required this.onToggle,
    this.palette = TagPillPalette.app,
    super.key,
  });

  final String playerName;
  final List<String> selectedIds;
  final ValueChanged<GameTag> onToggle;
  final TagPillPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.playerTagsSheetTitle(playerName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('player_tags_sheet_done'),
                  onPressed: () => Navigator.of(context).pop(),
                  // Each tap already updates the draft, so this only closes
                  // the sheet; "Save" tells the user the picks are kept.
                  child: Text(
                    l10n.saveButtonLabel,
                    style: TextStyle(color: palette.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GameTagPicker(
              scope: GameTagScope.player,
              selectedIds: selectedIds,
              onToggle: onToggle,
              palette: palette,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
