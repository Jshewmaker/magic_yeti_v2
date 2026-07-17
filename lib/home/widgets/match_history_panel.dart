import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/home/widgets/match_history_list_item.dart';
import 'package:magic_yeti/home/widgets/match_history_skeleton.dart';
import 'package:magic_yeti/l10n/l10n.dart';

/// The scrolling list of the player's past games.
///
/// Purely presentational: loading and clearing the history is driven by
/// auth changes at the app level, never from here.
class MatchHistoryPanel extends StatelessWidget {
  const MatchHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<MatchHistoryBloc, MatchHistoryState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == MatchHistoryStatus.gameNotFound,
      listener: (context, state) {
        showToast(
          context,
          Toast.error(message: l10n.gameNotFoundError),
        );
      },
      child: BlocBuilder<MatchHistoryBloc, MatchHistoryState>(
        builder: (context, state) {
          switch (state.status) {
            case MatchHistoryStatus.initial:
            case MatchHistoryStatus.loadingHistory:
              return const MatchHistorySkeleton();
            case MatchHistoryStatus.failure:
              return Center(
                child: Text(l10n.matchHistoryLoadError),
              );
            case MatchHistoryStatus.gameNotFound:
            case MatchHistoryStatus.loadingHistorySuccess:
              if (state.games.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noMatchHistoryAvailable,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }
              return ListView.builder(
                itemCount: state.games.length,
                itemBuilder: (context, index) =>
                    MatchHistoryListItem(game: state.games[index]),
              );
          }
        },
      ),
    );
  }
}
