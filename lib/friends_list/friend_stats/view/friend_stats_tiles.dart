import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head.dart';
import 'package:magic_yeti/stats_overview/widgets/stats_widget.dart';

/// The hero tile: a pairwise finish record. This is the one stat with both a
/// real sample and a real story at ~10 pods — "who finishes ahead" is defined
/// in every shared pod with a true 50% baseline, unlike a 25%-event win rate.
class LedgerHeroTile extends StatelessWidget {
  const LedgerHeroTile({
    required this.stats,
    required this.friendName,
    super.key,
  });

  final FriendHeadToHead stats;
  final String friendName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enough = stats.hasEnoughForLedger;

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              'The Ledger',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            if (enough) ...[
              Text(
                '${stats.youFinishedAhead}–${stats.theyFinishedAhead}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'you finish ahead in ${stats.youFinishedAhead} '
                'of ${stats.sharedPods} pods',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral60,
                ),
                textAlign: TextAlign.center,
              ),
            ] else
              Text(
                'Need 3+ pods together',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral60,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Builds the secondary stat tiles for the grid, applying each stat's sample
/// gate. Damage tiles (The Beatdown, 21s) are omitted entirely below their
/// gates rather than shown as a rivalry of zeroes.
List<Widget> buildFriendStatTiles(FriendHeadToHead stats) {
  int pct(double? f) => ((f ?? 0) * 100).round();

  return [
    StatsWidget(
      title: 'Pods Won',
      stat: stats.hasEnoughForLedger
          ? '${stats.youWon}·${stats.theyWon}·${stats.fieldWon}'
          : 'Need 3+',
      tooltip:
          'You · Them · Rest of the table, across ${stats.sharedPods} '
          'pods. An even split would be about '
          '${stats.expectedWinsEach.toStringAsFixed(1)} each — in a 4-player '
          'pod the baseline is 25%, not 50%.',
    ),
    StatsWidget(
      title: 'Their Go-To',
      stat: stats.hasEnoughForTopCommander
          ? (stats.theirTopCommanderName ?? 'Need 3+')
          : 'Need 3+',
      tooltip: stats.hasEnoughForTopCommander
          ? 'The commander they bring to your table most often '
                '(${stats.theirTopCommanderCount} of ${stats.sharedPods} pods).'
          : 'Their most-played commander at your table (needs 3+ pods).',
    ),
    StatsWidget(
      title: 'Time Alive',
      stat: stats.hasEnoughForSurvival
          ? '${pct(stats.yourAvgSurvival)}% / ${pct(stats.theirAvgSurvival)}%'
          : 'Need 5+',
      tooltip:
          'Average share of the pod each of you survives — you / them. '
          'The Ledger says who outlasts whom; this says by how much.',
    ),
    StatsWidget(
      title: 'Final Two',
      stat: stats.hasEnoughForFinalTwo
          ? '${stats.finalTwoCount} of ${stats.sharedPods}'
          : 'Need 5+',
      tooltip:
          'Pods where the two of you were the last players standing — '
          'the mark of a real rivalry.',
    ),
    if (stats.hasBeatdown)
      StatsWidget(
        title: 'The Beatdown',
        stat: '${stats.commanderDamageDealt} / ${stats.commanderDamageTaken}',
        tooltip:
            'Total commander damage you have dealt to them / taken from '
            'them across your shared pods.',
      ),
    if (stats.hasLethalBlows)
      StatsWidget(
        title: '21s',
        stat: '${stats.lethalBlowsLanded} / ${stats.lethalBlowsTaken}',
        tooltip:
            'Pods where a single commander landed the lethal 21 — you on '
            'them / them on you.',
      ),
  ];
}
