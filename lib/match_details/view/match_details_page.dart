import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/models/models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:player_repository/models/player.dart';
import 'package:url_launcher/url_launcher.dart';

class MatchDetailsPage extends StatelessWidget {
  const MatchDetailsPage({
    required this.game,
    super.key,
  });

  factory MatchDetailsPage.pageBuilder(
    _,
    GoRouterState state,
  ) {
    final game = state.extra as GameModel?;
    return MatchDetailsPage(game: game!);
  }

  final GameModel game;

  static const routeName = 'match_details_page';
  static String get routePath => '/match_details_page';

  @override
  Widget build(BuildContext context) {
    return MatchDetailsView(game: game);
  }
}

class MatchDetailsView extends StatelessWidget {
  const MatchDetailsView({
    required this.game,
    super.key,
  });

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final winner = game.winner;
    final gameDuration = game.durationInSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.matchDetailsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      MatchWinnerWidget(
                        winner: winner,
                        gameDuration: gameDuration,
                        startingPlayerId: game.startingPlayerId,
                      ),
                      const SizedBox(height: 16),
                      MatchStandingsWidget(
                        players: game.players,
                        winner: winner,
                      ),
                      const SizedBox(height: 16),
                      MatchMetadataWidget(
                        game: game,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class MatchWinnerWidget extends StatelessWidget {
  const MatchWinnerWidget({
    required this.winner,
    required this.gameDuration,
    required this.startingPlayerId,
    super.key,
  });

  final Player winner;
  final int gameDuration;
  final String startingPlayerId;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.winner.withValues(alpha: .6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: winner.commander?.imageUrl != null &&
                          winner.commander!.imageUrl.isNotEmpty
                      ? NetworkImage(winner.commander!.imageUrl)
                      : null,
                  backgroundColor: winner.commander?.imageUrl != null &&
                          winner.commander!.imageUrl.isNotEmpty
                      ? null
                      : Color(winner.color),
                  radius: 50,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Winner: ${winner.name}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        children: [
                          Text(
                            'Commander: ${winner.commander?.name}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (winner.commander == null)
                            const SizedBox.shrink()
                          else
                            LinkWidget(uri: winner.commander?.scryFallUrl),
                        ],
                      ),
                      if (winner.id == startingPlayerId)
                        const Text('Started First'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Game Duration: ${_formatDuration(gameDuration)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class LinkWidget extends StatelessWidget {
  const LinkWidget({
    required this.uri,
    super.key,
  });

  final String? uri;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.link, color: AppColors.neutral60),
      onPressed: () async {
        final url = Uri.parse(
          uri ?? '',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      },
      tooltip: 'View on Scryfall',
    );
  }
}

class MatchStandingsWidget extends StatelessWidget {
  const MatchStandingsWidget({
    required this.players,
    required this.winner,
    super.key,
  });

  final List<Player> players;
  final Player winner;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Players',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...players.map(
              (player) => ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      NetworkImage(player.commander?.imageUrl ?? ''),
                ),
                title: Text(player.name),
                subtitle: Row(
                  children: [
                    Text(player.commander?.name ?? ''),
                    LinkWidget(uri: player.commander?.scryFallUrl),
                  ],
                ),
                trailing: player.id == winner.id
                    ? const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchMetadataWidget extends StatelessWidget {
  const MatchMetadataWidget({
    required this.game,
    super.key,
  });

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Room ID: ${game.roomId}'),
            Text(
              'Played on: ${game.endTime.toLocal().toString().split('.')[0]}',
            ),
            // Text('Starting Life: ${game.}'),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final minutes = duration.inMinutes;
  final remainingSeconds = duration.inSeconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}
