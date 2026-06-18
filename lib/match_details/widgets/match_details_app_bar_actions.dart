import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';

class MatchDetailsAppBarActions extends StatelessWidget {
  const MatchDetailsAppBarActions({
    required this.game,
    required this.deleteAction,
    super.key,
  });

  final GameModel game;
  final Widget deleteAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<MatchEditCubit, MatchEditState>(
      builder: (context, state) {
        if (state.isEditing) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.cancelButtonLabel,
                icon: const Icon(Icons.close),
                onPressed: () => context.read<MatchEditCubit>().cancel(),
              ),
              IconButton(
                tooltip: l10n.saveButtonLabel,
                icon: const Icon(Icons.check),
                onPressed: state.status == MatchEditStatus.saving
                    ? null
                    : () => context.read<MatchEditCubit>().save(),
              ),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.editMatchTooltip,
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.read<MatchEditCubit>().startEditing(game),
            ),
            deleteAction,
          ],
        );
      },
    );
  }
}
