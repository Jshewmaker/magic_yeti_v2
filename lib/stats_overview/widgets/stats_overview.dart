import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:magic_yeti/stats_overview/widgets/widgets.dart';

class StatsOverviewWidget extends StatelessWidget {
  const StatsOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) => StatsOverviewBloc()
        ..add(
          CompileStatsOverviewData(
            userId: context.read<AppBloc>().state.user.id,
            games: context.read<MatchHistoryBloc>().state.games,
          ),
        ),
      child: BlocBuilder<StatsOverviewBloc, StatsOverviewState>(
        builder: (context, state) {
          if (state is StatsOverviewLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is StatsOverviewLoaded) {
            return GridView.count(
              crossAxisSpacing: 50,
              childAspectRatio: .6,
              mainAxisSpacing: 10,
              crossAxisCount: 3,
              children: [
                StatsWidget(
                  title: l10n.winRateTitle,
                  stat: '${state.winPercentage}%',
                ),
                StatsWidget(
                  title: l10n.totalWinsTitle,
                  stat: state.totalWins.toString(),
                ),
                StatsWidget(
                  title: l10n.totalGamesTitle,
                  stat: state.games.length.toString(),
                ),
                StatsWidget(
                  title: l10n.shortestGameTitle,
                  stat: state.shortestGameDuration,
                ),
                StatsWidget(
                  title: l10n.longestGameTitle,
                  stat: state.longestGameDuration,
                ),
                StatsWidget(
                  title: l10n.averagePlacementTitle,
                  stat: state.averagePlacement.toString(),
                ),
                StatsWidget(
                  title: l10n.uniqueCommandersTitle,
                  stat: state.uniqueCommanderCount.toString(),
                ),
                StatsWidget(
                  title: l10n.timesWentFirstTitle,
                  stat: state.timesWentFirst.toString(),
                ),
                StatsWidget(
                  title: l10n.mostPlayedCommanderTitle,
                  stat: state.mostPlayedCommander,
                ),
              ],
            );
          }
          return const Text('No data available');
        },
      ),
    );
  }
}
