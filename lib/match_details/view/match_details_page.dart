import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/home/bloc/match_history_bloc.dart';
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

  void _handlePlayerSelection(BuildContext context, Player player) {
    final currentUserFirebaseId = game.hostId;

    // Dispatch event to update player ownership
    context.read<MatchHistoryBloc>().add(
          UpdatePlayerOwnership(
            game: game,
            player: player,
            currentUserFirebaseId: currentUserFirebaseId,
          ),
        );

    // Show a confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You were ${player.name} in this game'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final winner = game.winner;
    final gameDuration = game.durationInSeconds;

    return BlocListener<MatchHistoryBloc, MatchHistoryState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == HomeStatus.failure,
      listener: (context, state) {
        if (state.status == HomeStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save: ${state.error}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
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
                          currentUserFirebaseId: game.hostId,
                          onSelectPlayer: (player) =>
                              _handlePlayerSelection(context, player),
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
    required this.currentUserFirebaseId,
    required this.onSelectPlayer,
    super.key,
  });

  final List<Player> players;
  final Player winner;
  final String? currentUserFirebaseId;
  final void Function(Player) onSelectPlayer;

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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (player.firebaseId == currentUserFirebaseId)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.person,
                          color: Colors.blue,
                        ),
                      ),
                    if (player.id == winner.id)
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                      ),
                    if (player.firebaseId != currentUserFirebaseId)
                      TextButton(
                        onPressed: () => onSelectPlayer(player),
                        child: const Text('This is me'),
                      ),
                  ],
                ),
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
