import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game_tags/game_tags.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/home/widgets/match_format_filter.dart';
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
      _compileStats(matchHistoryState.filteredGames);
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

  void _onTagChanged(GameTag? tag) {
    context.read<StatsOverviewBloc>().add(StatsTagFilterChanged(tag));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The stats follow the same EDH / constructed filter as the match
    // history.
    final formatFilter = context.select<MatchHistoryBloc, MatchFormatFilter>(
      (bloc) => bloc.state.formatFilter,
    );
    return BlocListener<MatchHistoryBloc, MatchHistoryState>(
      listenWhen: (previous, current) =>
          !identical(previous.games, current.games) ||
          previous.formatFilter != current.formatFilter,
      listener: (context, state) => _compileStats(state.filteredGames),
      child: BlocBuilder<StatsOverviewBloc, StatsOverviewState>(
        builder: (context, state) {
          if (state is StatsOverviewLoaded) {
            return Column(
              children: [
                _buildFilters(
                  context,
                  range: state.range,
                  tag: state.tag,
                  availableTags: state.availableTags,
                ),
                Expanded(
                  child: StatsGrid(
                    children: _buildStatWidgets(
                      l10n,
                      state,
                      showCommanderDamage:
                          formatFilter != MatchFormatFilter.constructed,
                    ),
                  ),
                ),
              ],
            );
          }
          if (state is StatsOverviewFailure) {
            return Column(
              children: [
                _buildFilters(context, range: StatsTimeRange.allTime),
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

  /// The format filter on the left; the tag filter (only when the user has
  /// tagged games) and the time range on the right.
  Widget _buildFilters(
    BuildContext context, {
    required StatsTimeRange range,
    GameTag? tag,
    List<GameTag> availableTags = const [],
  }) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      // Full width, so the format filter sits left and the tag and range
      // filters sit right. Wraps onto two lines when they do not fit side by
      // side.
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const MatchFormatFilterDropdown(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (availableTags.isNotEmpty) ...[
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: _styledDropdown<GameTag?>(
                        key: const Key('stats_tag_filter'),
                        context: context,
                        // Fills the box so a long tag label ellipsizes.
                        isExpanded: true,
                        value: tag,
                        items: [
                          DropdownMenuItem<GameTag?>(
                            child: Text(l10n.statsTagFilterAll),
                          ),
                          for (final option in availableTags)
                            DropdownMenuItem<GameTag?>(
                              value: option,
                              child: Text(
                                option.label(l10n),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _onTagChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                _styledDropdown<StatsTimeRange>(
                  context: context,
                  value: range,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _styledDropdown<T>({
    required BuildContext context,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool isExpanded = false,
    Key? key,
  }) {
    return DropdownButton<T>(
      key: key,
      value: value,
      isExpanded: isExpanded,
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
      items: items,
      onChanged: onChanged,
    );
  }

  List<Widget> _buildStatWidgets(
    AppLocalizations l10n,
    StatsOverviewLoaded state, {
    required bool showCommanderDamage,
  }) {
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
      // 1v1 constructed games have no commander damage.
      if (showCommanderDamage) ...[
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
      ],
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
