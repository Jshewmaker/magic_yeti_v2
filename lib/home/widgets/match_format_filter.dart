import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';

/// Picks which games the home screen shows: all, EDH, or constructed.
///
/// The choice lives in [MatchHistoryBloc], so every copy of this dropdown
/// (above the match history and above the stats) stays in sync.
class MatchFormatFilterDropdown extends StatelessWidget {
  const MatchFormatFilterDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = context.select<MatchHistoryBloc, MatchFormatFilter>(
      (bloc) => bloc.state.formatFilter,
    );
    return DropdownButton<MatchFormatFilter>(
      key: const Key('match_format_filter_dropdown'),
      value: filter,
      dropdownColor: Colors.grey[900],
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
      underline: Container(
        height: 1,
        color: Colors.blueGrey.withAlpha(100),
      ),
      icon: const Icon(Icons.filter_list, color: Colors.blueGrey, size: 18),
      items: [
        for (final option in MatchFormatFilter.values)
          DropdownMenuItem(
            value: option,
            child: Text(switch (option) {
              MatchFormatFilter.all => l10n.matchFormatAll,
              MatchFormatFilter.commander => l10n.matchFormatCommander,
              MatchFormatFilter.constructed => l10n.matchFormatConstructed,
            }),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        context.read<MatchHistoryBloc>().add(MatchFormatFilterChanged(value));
      },
    );
  }
}
