import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

/// The player's aggregate stats, recomputed whenever the match history
/// changes or the selected time range changes.
///
/// The [StatsOverviewBloc] is created once for the widget's lifetime; match
/// history updates flow in through a [BlocListener] rather than by
/// recreating the bloc.
class StatsOverviewWidget extends StatelessWidget {
  const StatsOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatsOverviewBloc(
        scryfallRepository: context.read<ScryfallRepository>(),
      ),
      child: const _StatsOverviewView(),
    );
  }
}

class _StatsOverviewView extends StatefulWidget {
  const _StatsOverviewView();

  @override
  State<_StatsOverviewView> createState() => _StatsOverviewViewState();
}

class _StatsOverviewViewState extends State<_StatsOverviewView> {
  @override
  void initState() {
    super.initState();
    // Compile immediately if the match history has already loaded; otherwise
    // the BlocListener below fires when the games arrive.
    final matchHistoryState = context.read<MatchHistoryBloc>().state;
    if (matchHistoryState.status == MatchHistoryStatus.loadingHistorySuccess ||
        matchHistoryState.status == MatchHistoryStatus.gameNotFound) {
      _compileStats(matchHistoryState.games);
    }
  }

  void _compileStats(List<GameModel> games) {
    context.read<StatsOverviewBloc>().add(
      CompileStatsOverviewData(
        userId: context.read<AppBloc>().state.user.id,
        games: games,
      ),
    );
  }

  void _onRangeChanged(StatsTimeRange? range) {
    if (range == null) return;
    context.read<StatsOverviewBloc>().add(StatsTimeRangeChanged(range));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<MatchHistoryBloc, MatchHistoryState>(
      listenWhen: (previous, current) =>
          !identical(previous.games, current.games),
      listener: (context, state) => _compileStats(state.games),
      child: BlocBuilder<StatsOverviewBloc, StatsOverviewState>(
        builder: (context, state) {
          if (state is StatsOverviewLoaded) {
            return Column(
              children: [
                _buildDropdown(context, state.range),
                Expanded(
                  child: StatsGrid(children: _buildStatWidgets(l10n, state)),
                ),
              ],
            );
          }
          if (state is StatsOverviewFailure) {
            return Column(
              children: [
                _buildDropdown(context, StatsTimeRange.allTime),
                const Expanded(
                  child: Center(
                    child: Text('No data available'),
                  ),
                ),
              ],
            );
          }
          // No compiled data yet: initial load, or a compile in flight.
          return const StatsOverviewSkeleton();
        },
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, StatsTimeRange range) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: DropdownButton<StatsTimeRange>(
          value: range,
          dropdownColor: Colors.grey[900],
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
          underline: Container(
            height: 1,
            color: Colors.blueGrey.withAlpha(100),
          ),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.blueGrey,
          ),
          items: StatsTimeRange.values
              .map(
                (range) => DropdownMenuItem<StatsTimeRange>(
                  value: range,
                  child: Text(range.label),
                ),
              )
              .toList(),
          onChanged: _onRangeChanged,
        ),
      ),
    );
  }

  List<Widget> _buildStatWidgets(
    AppLocalizations l10n,
    StatsOverviewLoaded state,
  ) {
    return [
      StatsWidget(
        title: l10n.winRateTitle,
        stat: '${state.winPercentage}%',
        tooltip: 'Percentage of games you won',
      ),
      StatsWidget(
        title: l10n.totalWinsTitle,
        stat: state.totalWins.toString(),
        tooltip: 'Total number of games won',
      ),
      StatsWidget(
        title: l10n.totalGamesTitle,
        stat: state.games.length.toString(),
        tooltip: 'Total number of games played',
      ),
      StatsWidget(
        title: l10n.shortestGameTitle,
        stat: state.shortestGameDuration,
        tooltip: 'Duration of your shortest game',
      ),
      StatsWidget(
        title: l10n.longestGameTitle,
        stat: state.longestGameDuration,
        tooltip: 'Duration of your longest game',
      ),
      StatsWidget(
        title: l10n.averagePlacementTitle,
        stat: state.averagePlacement.toString(),
        tooltip:
            'Your average finishing position '
            'across all games',
      ),
      StatsWidget(
        title: l10n.uniqueCommandersTitle,
        stat: state.uniqueCommanderCount.toString(),
        tooltip:
            'Number of different commanders '
            'you have played',
      ),
      StatsWidget(
        title: l10n.timesWentFirstTitle,
        stat: state.timesWentFirst.toString(),
        tooltip:
            'Number of games where you were '
            'the starting player',
      ),
      StatsWidget(
        title: l10n.mostPlayedCommanderTitle,
        stat: state.mostPlayedCommander,
        tooltip:
            'The commander you have played '
            'the most games with',
      ),
      StatsWidget(
        title: l10n.averageGameDurationTitle,
        stat: state.averageGameDuration,
        tooltip: 'Mean game length across all your games',
      ),
      StatsWidget(
        title: l10n.winRateWhenFirstTitle,
        stat: state.winRateWhenFirst,
        tooltip:
            'Your win percentage in games '
            'where you went first (min 3 games)',
      ),
      StatsWidget(
        title: l10n.bestCommanderTitle,
        stat: state.bestCommander,
        tooltip:
            'Commander with your highest '
            'win rate (min 3 games)',
      ),
      StatsWidget(
        title: l10n.currentStreakTitle,
        stat: state.currentStreak,
        tooltip:
            'Your current consecutive '
            'win (W) or loss (L) streak',
      ),
      StatsWidget(
        title: l10n.mostCommonOpponentTitle,
        stat: state.mostCommonOpponent,
        tooltip:
            'The opponent you have played '
            'against the most (min 3 games)',
      ),
      StatsWidget(
        title: l10n.nemesisTitle,
        stat: state.nemesis,
        tooltip:
            'The opponent who has beaten you '
            'the most (min 3 games)',
      ),
      StatsWidget(
        title: l10n.avgCommanderDamageTakenTitle,
        stat: state.avgCommanderDamageTaken,
        tooltip:
            'Average total commander damage '
            'you receive per game',
      ),
      StatsWidget(
        title: l10n.timesKilledByCommanderTitle,
        stat: state.timesKilledByCommander.toString(),
        tooltip:
            'Games where you took 21+ '
            'commander damage from a single '
            'opponent',
      ),
      StatsWidget(
        title: l10n.bestColorComboTitle,
        stat: state.bestColorCombo,
        tooltip:
            'Exact color identity combo '
            'with your highest win rate '
            '(min 3 games)',
      ),
      StatsWidget(
        title: l10n.bestSingleColorTitle,
        stat: state.bestSingleColor,
        tooltip:
            'Individual color that appears '
            'in your highest win rate '
            'commanders (min 3 games)',
      ),
    ];
  }
}
