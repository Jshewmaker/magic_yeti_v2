import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';

/// Floating action button that prompts for a room id and adds that game to
/// the player's match history.
class AddMatchFab extends StatelessWidget {
  const AddMatchFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      foregroundColor: AppColors.white,
      backgroundColor: AppColors.tertiary,
      // MatchHistoryBloc and AppBloc are provided above the root navigator,
      // so the dialog's context can read them directly.
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => const _AddMatchDialog(),
      ),
      child: const Icon(Icons.add),
    );
  }
}

class _AddMatchDialog extends StatefulWidget {
  const _AddMatchDialog();

  @override
  State<_AddMatchDialog> createState() => _AddMatchDialogState();
}

class _AddMatchDialogState extends State<_AddMatchDialog> {
  var _roomId = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.addGameToHistoryTitle),
      content: TextField(
        autocorrect: false,
        onChanged: (value) => _roomId = value.toUpperCase(),
        decoration: InputDecoration(
          hintText: l10n.enterRoomIdHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelTextButton),
        ),
        TextButton(
          onPressed: () {
            if (_roomId.isNotEmpty) {
              context.read<MatchHistoryBloc>().add(
                AddMatchToPlayerHistoryEvent(
                  roomId: _roomId,
                  playerId: context.read<AppBloc>().state.user.id,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: Text(l10n.addButtonText),
        ),
      ],
    );
  }
}
