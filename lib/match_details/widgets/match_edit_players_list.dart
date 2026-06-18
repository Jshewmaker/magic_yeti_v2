// lib/match_details/widgets/match_edit_players_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';
import 'package:magic_yeti/match_details/widgets/commander_picker.dart';
import 'package:magic_yeti/match_details/widgets/editable_player_tile.dart';

class MatchEditPlayersList extends StatelessWidget {
  const MatchEditPlayersList({
    this.pickCommander = showCommanderPicker,
    super.key,
  });

  final PickCommander pickCommander;

  Future<void> _pickCommander(BuildContext context, String playerId) async {
    final cubit = context.read<MatchEditCubit>();
    final commander = await pickCommander(context, selectingPartner: false);
    if (commander != null) {
      cubit.setCommander(playerId, commander);
    }
  }

  Future<void> _pickPartner(BuildContext context, String playerId) async {
    final cubit = context.read<MatchEditCubit>();
    final commander = await pickCommander(context, selectingPartner: true);
    if (commander != null) {
      cubit.setPartner(playerId, commander);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchEditCubit, MatchEditState>(
      builder: (context, state) {
        return Column(
          children: [
            for (final player in state.draftPlayers)
              EditablePlayerTile(
                key: ValueKey('editable-tile-${player.id}'),
                player: player,
                onNameChanged: (name) =>
                    context.read<MatchEditCubit>().updateName(player.id, name),
                onTapCommander: () => _pickCommander(context, player.id),
                onTapPartner: () => _pickPartner(context, player.id),
                onRemovePartner: () =>
                    context.read<MatchEditCubit>().setPartner(player.id, null),
              ),
          ],
        );
      },
    );
  }
}
