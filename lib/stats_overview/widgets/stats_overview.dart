import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/app/utils/device_info_provider.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

enum StatsTimeRange {
  allTime('All Time'),
  last12Months('Last 12 Months'),
  last6Months('Last 6 Months'),
  last3Months('Last 3 Months'),
  last30Days('Last 30 Days');

  const StatsTimeRange(this.label);
  final String label;
}

class StatsOverviewWidget extends StatefulWidget {
  const StatsOverviewWidget({super.key});

  @override
  State<StatsOverviewWidget> createState() => _StatsOverviewWidgetState();
}

class _StatsOverviewWidgetState extends State<StatsOverviewWidget> {
  StatsTimeRange _selectedRange = StatsTimeRange.allTime;

  List<GameModel> _filterGames(List<GameModel> games) {
    if (_selectedRange == StatsTimeRange.allTime) {
      return games;
    }
    final now = DateTime.now();
    final cutoff = switch (_selectedRange) {
      StatsTimeRange.last12Months => DateTime(now.year - 1, now.month, now.day),
      StatsTimeRange.last6Months => DateTime(now.year, now.month - 6, now.day),
      StatsTimeRange.last3Months => DateTime(now.year, now.month - 3, now.day),
      StatsTimeRange.last30Days => now.subtract(const Duration(days: 30)),
      StatsTimeRange.allTime => now,
    };
    return games.where((game) => game.endTime.isAfter(cutoff)).toList();
  }

  void _onRangeChanged(
    StatsTimeRange? range,
    BuildContext blocContext,
  ) {
    if (range == null) return;
    setState(() => _selectedRange = range);
    final allGames = blocContext.read<MatchHistoryBloc>().state.games;
    blocContext.read<StatsOverviewBloc>().add(
      CompileStatsOverviewData(
        userId: blocContext.read<AppBloc>().state.user.id,
        games: _filterGames(allGames),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPhone = DeviceInfoProvider.of(context).isPhone;
    final allGames = context.read<MatchHistoryBloc>().state.games;
    return BlocProvider(
      create: (context) =>
          StatsOverviewBloc(
            scryfallRepository: context.read<ScryfallRepository>(),
          )..add(
            CompileStatsOverviewData(
              userId: context.read<AppBloc>().state.user.id,
              games: _filterGames(allGames),
            ),
          ),
      child: BlocBuilder<StatsOverviewBloc, StatsOverviewState>(
        builder: (context, state) {
          if (state is StatsOverviewLoading) {
            return Column(
              children: [
                _buildDropdown(context),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            );
          }
          if (state is StatsOverviewLoaded) {
            return Column(
              children: [
                _buildDropdown(context),
                Expanded(
                  child: GridView.count(
                    crossAxisSpacing: 50,
                    childAspectRatio: isPhone ? .8 : 1.2,
                    mainAxisSpacing: 10,
                    crossAxisCount: 3,
                    children: _buildStatWidgets(l10n, state),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _buildDropdown(context),
              const Expanded(
                child: Center(
                  child: Text('No data available'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdown(BuildContext blocContext) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: DropdownButton<StatsTimeRange>(
          value: _selectedRange,
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
          onChanged: (range) => _onRangeChanged(range, blocContext),
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
