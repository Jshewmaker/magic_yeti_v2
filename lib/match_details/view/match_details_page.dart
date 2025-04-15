import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/app/utils/device_info_provider.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/match_details/match_details.dart';
import 'package:player_repository/models/player.dart';
import 'package:url_launcher/url_launcher.dart';

class MatchDetailsPage extends StatelessWidget {
  const MatchDetailsPage({
    required this.gameId,
    super.key,
  });

  factory MatchDetailsPage.pageBuilder(_, GoRouterState state) {
    return MatchDetailsPage(gameId: state.pathParameters['gameId']!);
  }

  final String gameId;

  static const routeName = 'match_details_page';
  static String get routePath => '/match_details_page/:gameId';
  static String path({required String gameId}) => '/match_details_page/$gameId';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MatchDetailsBloc(
        databaseRepository: context.read<FirebaseDatabaseRepository>(),
      ),
      child: MatchDetailsView(gameId: gameId),
    );
  }
}

class MatchDetailsView extends StatelessWidget {
  const MatchDetailsView({
    required this.gameId,
    super.key,
  });

  final String gameId;

  @override
  Widget build(BuildContext context) {
    // Use DeviceInfoProvider to determine if the device is a phone
    final isPhone = DeviceInfoProvider.of(context).isPhone;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    return BlocConsumer<MatchDetailsBloc, MatchDetailsState>(
      listener: (context, state) {
        if (state is MatchDetailsDeleted) {
          context.go(HomePage.routeName);
        } else if (state is MatchDetailsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.errorSnackbarMessage(state.error)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        final games = context.watch<MatchHistoryBloc>().state.games;
        final gameExists = games.any((game) => game.id == gameId);
        if (!gameExists) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Return the appropriate view based on device type
        return isPhone
            ? _PhoneMatchDetailsView(gameId: gameId)
            : _TabletMatchDetailsView(gameId: gameId);
      },
    );
  }
}

class _PhoneMatchDetailsView extends StatelessWidget {
  const _PhoneMatchDetailsView({
    required this.gameId,
  });

  final String gameId;

  void _handlePlayerSelection(BuildContext context, Player player) {
    final currentUserFirebaseId = context.read<AppBloc>().state.user.id;
    final game = context.read<MatchHistoryBloc>().state.games.firstWhere(
          (game) => game.id == gameId,
        );
    // Find the currently assigned player, if any
    final currentPlayer = game.players.firstWhere(
      (p) => p.firebaseId == currentUserFirebaseId,
      orElse: () => player,
    );

    // Dispatch event to update player ownership
    context.read<MatchDetailsBloc>().add(
          UpdatePlayerOwnership(
            game: game,
            player: player,
            currentUserFirebaseId: currentUserFirebaseId,
          ),
        );

    // Show a confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: currentPlayer.id != player.id
            ? Text(
                context.l10n.changedPlayerMessage(
                  currentPlayer.name,
                  player.name,
                ),
              )
            : Text(context.l10n.wasPlayerMessage(player.name)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final games = context.watch<MatchHistoryBloc>().state.games;
    final game = games.firstWhere((game) => game.id == gameId);
    final winningPlayer = game.players.firstWhere(
      (player) => player.id == game.winnerId,
    );
    final gameDuration = game.durationInSeconds;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.matchDetailsHeading),
        actions: [
          _DeleteMatchButton(gameId: gameId),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Winner card
              MatchWinnerWidget(
                winner: winningPlayer,
                gameDuration: gameDuration,
                startingPlayerId: game.startingPlayerId,
                gameId: gameId,
              ),
              const SizedBox(height: 16),
              // Players standings
              MatchStandingsWidget(
                players: game.players,
                winner: winningPlayer,
                currentUserFirebaseId: game.hostId,
                startingPlayerId: game.startingPlayerId,
                onSelectPlayer: (player) =>
                    _handlePlayerSelection(context, player),
              ),
              const SizedBox(height: 16),
              // Match metadata
              MatchMetadataWidget(
                game: game,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletMatchDetailsView extends StatelessWidget {
  const _TabletMatchDetailsView({
    required this.gameId,
  });

  final String gameId;

  void _handlePlayerSelection(BuildContext context, Player player) {
    final currentUserFirebaseId = context.read<AppBloc>().state.user.id;
    final game = context.read<MatchHistoryBloc>().state.games.firstWhere(
          (game) => game.id == gameId,
        );
    // Find the currently assigned player, if any
    final currentPlayer = game.players.firstWhere(
      (p) => p.firebaseId == currentUserFirebaseId,
      orElse: () => player,
    );

    // Dispatch event to update player ownership
    context.read<MatchDetailsBloc>().add(
          UpdatePlayerOwnership(
            game: game,
            player: player,
            currentUserFirebaseId: currentUserFirebaseId,
          ),
        );

    // Show a confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: currentPlayer.id != player.id
            ? Text(
                context.l10n.changedPlayerMessage(
                  currentPlayer.name,
                  player.name,
                ),
              )
            : Text(context.l10n.wasPlayerMessage(player.name)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final games = context.watch<MatchHistoryBloc>().state.games;
    final game = games.firstWhere((game) => game.id == gameId);
    final winningPlayer = game.players.firstWhere(
      (player) => player.id == game.winnerId,
    );
    final gameDuration = game.durationInSeconds;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          _DeleteMatchButton(gameId: gameId),
        ],
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
                        l10n.matchDetailsHeading,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      MatchWinnerWidget(
                        winner: winningPlayer,
                        gameDuration: gameDuration,
                        startingPlayerId: game.startingPlayerId,
                        gameId: gameId,
                      ),
                      const SizedBox(height: 16),
                      MatchStandingsWidget(
                        players: game.players,
                        winner: winningPlayer,
                        currentUserFirebaseId: game.hostId,
                        startingPlayerId: game.startingPlayerId,
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
    );
  }
}

class MatchWinnerWidget extends StatelessWidget {
  const MatchWinnerWidget({
    required this.winner,
    required this.gameDuration,
    required this.startingPlayerId,
    required this.gameId,
    super.key,
  });

  final Player winner;
  final int gameDuration;
  final String startingPlayerId;
  final String gameId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                  backgroundImage:
                      winner.commander?.imageUrl.isNotEmpty ?? false
                          ? NetworkImage(winner.commander!.imageUrl)
                          : null,
                  backgroundColor: Color(winner.color),
                  radius: 50,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.winnerLabel(winner.name),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (winner.commander?.name != null)
                        Row(
                          children: [
                            Text(
                              l10n.commanderLabel(
                                winner.commander?.name ?? '',
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            LinkWidget(
                              uri: winner.commander?.scryFallUrl ?? '',
                            ),
                          ],
                        ),
                      if (winner.id == startingPlayerId)
                        Text('${winner.name} ${l10n.startedFirst}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.gameDuration} ${_formatDuration(gameDuration)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class LinkWidget extends StatelessWidget {
  const LinkWidget({
    this.uri = '',
    super.key,
  });

  final String uri;

  @override
  Widget build(BuildContext context) {
    return uri.isEmpty
        ? const SizedBox.shrink()
        : IconButton(
            icon: const Icon(Icons.link, color: AppColors.neutral60),
            onPressed: () async {
              final url = Uri.parse(
                uri,
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            tooltip: context.l10n.viewOnScryfall,
          );
  }
}

class MatchStandingsWidget extends StatelessWidget {
  const MatchStandingsWidget({
    required this.players,
    required this.winner,
    required this.currentUserFirebaseId,
    required this.startingPlayerId,
    required this.onSelectPlayer,
    super.key,
  });

  final List<Player> players;
  final Player winner;
  final String? currentUserFirebaseId;
  final String startingPlayerId;
  final void Function(Player) onSelectPlayer;

  String _getOrdinalNumber(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    players.sort((a, b) => a.placement.compareTo(b.placement));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:
              MainAxisSize.min, // Prevent Column from expanding infinitely
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Placement header
                Expanded(
                  child: Text(
                    context.l10n.placementColumnHeader,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.l10n.achievementColumnHeader,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ),
                // Player name and commander header
                Expanded(
                  child: Text(
                    context.l10n.playerColumnHeader,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ),
              ],
            ),
            const Divider(),
            // Player rows
            ...players.map(
              (player) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Placement number
                    Expanded(
                      child: Text(
                        _getOrdinalNumber(player.placement),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        spacing: 8,
                        children: [
                          if (player.firebaseId != currentUserFirebaseId)
                            IconButton(
                              onPressed: () => onSelectPlayer(player),
                              icon: const FaIcon(
                                FontAwesomeIcons.userPlus,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                          if (player.firebaseId == currentUserFirebaseId)
                            Tooltip(
                              triggerMode: TooltipTriggerMode.tap,
                              message: l10n.youTooltip,
                              child: const IconButton(
                                icon: Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                ),
                                onPressed: null,
                              ),
                            ),
                          if (player.id == startingPlayerId)
                            Tooltip(
                              triggerMode: TooltipTriggerMode.tap,
                              message: l10n.wentFirstTooltip,
                              child: const FaIcon(
                                FontAwesomeIcons.one,
                                color: Colors.green,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundImage:
                          player.commander?.imageUrl.isNotEmpty ?? false
                              ? NetworkImage(player.commander!.imageUrl)
                              : null,
                      backgroundColor: Color(player.color),
                    ),
                    const SizedBox(width: 16),

                    // Player info and icons
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Player name
                          Row(
                            children: [
                              Text(
                                player.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          // Commander name and link
                          if (player.commander?.name != null)
                            LinkWidget(
                                uri: player.commander?.scryFallUrl ?? ''),
                        ],
                      ),
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
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.matchInformationHeading,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(
              context.l10n.roomIdLabel(game.roomId),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${l10n.playedOnLabel} ${DateFormat('MM/dd/yyyy').format(game.endTime.toLocal())}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteMatchButton extends StatelessWidget {
  const _DeleteMatchButton({
    required this.gameId,
  });

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchHistoryBloc, MatchHistoryState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return IconButton(
          onPressed: () {
            _showDeleteConfirmationDialog(context);
          },
          icon: const Icon(Icons.delete_outline),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: context.read<MatchDetailsBloc>(),
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(context.l10n.deleteMatchDialogTitle),
                content: Text(
                  context.l10n.deleteMatchDialogContent,
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text(context.l10n.cancelButtonLabel),
                  ),
                  HoldToConfirmButton(
                    child: Text(context.l10n.deleteMatchButtonLabel),
                    onProgressCompleted: () async {
                      context.read<MatchDetailsBloc>().add(
                            DeleteMatchEvent(
                              gameId: gameId,
                              userId: context.read<AppBloc>().state.user.id,
                            ),
                          );

                      context.pop();
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

String _formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final minutes = duration.inMinutes;
  final remainingSeconds = duration.inSeconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}
