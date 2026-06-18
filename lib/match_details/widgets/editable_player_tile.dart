// lib/match_details/widgets/editable_player_tile.dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:player_repository/player_repository.dart';

class EditablePlayerTile extends StatefulWidget {
  const EditablePlayerTile({
    required this.player,
    required this.onNameChanged,
    required this.onTapCommander,
    required this.onTapPartner,
    required this.onRemovePartner,
    super.key,
  });

  final Player player;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onTapCommander;
  final VoidCallback onTapPartner;
  final VoidCallback onRemovePartner;

  @override
  State<EditablePlayerTile> createState() => _EditablePlayerTileState();
}

class _EditablePlayerTileState extends State<EditablePlayerTile> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.player.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final player = widget.player;
    final partner = player.partner;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            GestureDetector(
              key: ValueKey('edit-commander-${player.id}'),
              onTap: widget.onTapCommander,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Color(player.color),
                backgroundImage: player.commander?.imageUrl.isNotEmpty ?? false
                    ? NetworkImage(player.commander!.imageUrl)
                    : null,
                child: player.commander == null
                    ? const Icon(Icons.add_a_photo, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    onChanged: widget.onNameChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: l10n.playerNameLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (partner == null)
                    TextButton.icon(
                      key: ValueKey('add-partner-${player.id}'),
                      onPressed: widget.onTapPartner,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.addPartnerLabel),
                    )
                  else
                    Row(
                      children: [
                        GestureDetector(
                          key: ValueKey('edit-partner-${player.id}'),
                          onTap: widget.onTapPartner,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(player.color),
                            backgroundImage: partner.imageUrl.isNotEmpty
                                ? NetworkImage(partner.imageUrl)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            partner.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          key: ValueKey('remove-partner-${player.id}'),
                          tooltip: l10n.removePartnerTooltip,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: widget.onRemovePartner,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
