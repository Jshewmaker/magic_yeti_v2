import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head.dart';

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

/// A single secondary head-to-head stat as a card: a clear title (with an
/// optional info button for the full explanation), the value, and a caption
/// that names what the value means so the info button is rarely needed.
class FriendStatCard extends StatelessWidget {
  const FriendStatCard({
    required this.title,
    required this.stat,
    required this.caption,
    this.tooltip,
    super.key,
  });

  final String title;
  final String stat;
  final String caption;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: AutoSizeText(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                if (tooltip != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: GestureDetector(
                      onTap: () => _showTooltip(context),
                      child: Icon(
                        Icons.info_outline,
                        size: 10,
                        color: Colors.blueGrey.withAlpha(150),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AutoSizeText(
              stat,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            AutoSizeText(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.neutral60,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          content: Text(tooltip!),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
    FriendStatCard(
      title: 'Pods Won',
      stat: stats.hasEnoughForLedger
          ? '${stats.youWon}·${stats.theyWon}·${stats.fieldWon}'
          : 'Need 3+',
      caption: 'You · Them · Field',
      tooltip:
          'You · Them · Rest of the table, across ${stats.sharedPods} '
          'pods. An even split would be about '
          '${stats.expectedWinsEach.toStringAsFixed(1)} each — in a 4-player '
          'pod the baseline is 25%, not 50%.',
    ),
    FriendStatCard(
      title: 'Their Go-To',
      stat: stats.hasEnoughForTopCommander
          ? (stats.theirTopCommanderName ?? 'Need 3+')
          : 'Need 3+',
      caption: 'Most-played cmdr',
      tooltip: stats.hasEnoughForTopCommander
          ? 'The commander they bring to your table most often '
                '(${stats.theirTopCommanderCount} of ${stats.sharedPods} pods).'
          : 'Their most-played commander at your table (needs 3+ pods).',
    ),
    FriendStatCard(
      title: 'Avg Time Alive',
      stat: stats.hasEnoughForSurvival
          ? '${pct(stats.yourAvgSurvival)}% / ${pct(stats.theirAvgSurvival)}%'
          : 'Need 5+',
      caption: 'You / Them survived',
      tooltip:
          'Average share of the pod each of you survives — you / them. '
          'The Ledger says who outlasts whom; this says by how much.',
    ),
    FriendStatCard(
      title: 'Final Two',
      stat: stats.hasEnoughForFinalTwo
          ? '${stats.finalTwoCount} of ${stats.sharedPods}'
          : 'Need 5+',
      caption: 'Last two standing',
      tooltip:
          'Pods where the two of you were the last players standing — '
          'the mark of a real rivalry.',
    ),
    if (stats.hasBeatdown)
      FriendStatCard(
        title: 'The Beatdown',
        stat: '${stats.commanderDamageDealt} / ${stats.commanderDamageTaken}',
        caption: 'Cmdr dmg dealt / taken',
        tooltip:
            'Total commander damage you have dealt to them / taken from '
            'them across your shared pods.',
      ),
    if (stats.hasLethalBlows)
      FriendStatCard(
        title: '21s',
        stat: '${stats.lethalBlowsLanded} / ${stats.lethalBlowsTaken}',
        caption: 'Lethal 21s: you / them',
        tooltip:
            'Pods where a single commander landed the lethal 21 — you on '
            'them / them on you.',
      ),
  ];
}
