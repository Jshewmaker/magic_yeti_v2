import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/bloc/match_history_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/life_counter.dart';
import 'package:magic_yeti/login/login.dart';
import 'package:magic_yeti/sign_up/sign_up.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  factory HomePage.pageBuilder(_, __) {
    return const HomePage(key: Key('home_page'));
  }

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MatchHistoryBloc(
        databaseRepository: context.read<FirebaseDatabaseRepository>(),
      )..add(
          LoadMatchHistory(userId: context.read<AppBloc>().state.user.id),
        ),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          Expanded(child: LeftSidePanel()),
          Expanded(child: MatchHistoryPanel()),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.onMorePressed,
  });
  final String title;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: const Border(
          right: BorderSide(width: 3, color: AppColors.background),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          if (onMorePressed != null)
            IconButton(
              onPressed: onMorePressed,
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class LeftSidePanel extends StatelessWidget {
  const LeftSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onMore =
        context.watch<AppBloc>().state.status == AppStatus.authenticated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.gameModeTitle),
        Expanded(
          child: GameModeButtons(l10n: l10n),
        ),
        Expanded(
          child: Column(
            children: [
              SectionHeader(
                title: l10n.statsTitle,
                onMorePressed: onMore
                    ? () {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext _) => AlertDialog(
                            title: const Text('Logout'),
                            content:
                                const Text('Are you sure you want to logout?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context
                                      .read<AppBloc>()
                                      .add(const AppLogoutRequested());
                                  context
                                      .read<MatchHistoryBloc>()
                                      .add(const ClearMatchHistory());
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
              ),
              const AccountWidget(),
            ],
          ),
        ),
      ],
    );
  }
}

class AccountWidget extends StatelessWidget {
  const AccountWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final userIsLoggedIn =
        context.select((AppBloc bloc) => bloc.state.user.isAnonymous);
    final l10n = context.l10n;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!userIsLoggedIn)
            Text(
              'More Stats coming soon!',
              style: Theme.of(context).textTheme.headlineLarge,
            )
          else ...[
            ElevatedButton(
              onPressed: () => context.go(LoginPage.routeName),
              child: Text(l10n.loginButtonText),
            ),
            ElevatedButton(
              onPressed: () => context.go(SignUpPage.routeName),
              child: Text(l10n.signUpAppBarTitle),
            ),
          ],
        ],
      ),
    );
  }
}

class GameModeButtons extends StatelessWidget {
  const GameModeButtons({
    required this.l10n,
    super.key,
  });
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.yellow,
                    Colors.black,
                    Colors.yellow,
                    Colors.black,
                    Colors.yellow,
                    Colors.yellow
                  ],
                  stops: [0.2, 0.4, 0.6, 0.8, 1, 1.2],
                  tileMode: TileMode.repeated,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _createGame(context, 2, 20),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.numberOfPlayers(2),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Under Construction',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.construction,
                          color: Colors.yellow,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () => _createGame(context, 4, 40),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                ),
                child: Center(
                  child: Text(
                    l10n.numberOfPlayers(4),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createGame(BuildContext context, int players, int lifePoints) {
    unawaited(WakelockPlus.enable());

    context.read<GameBloc>().add(
          CreateGameEvent(
            numberOfPlayers: players,
            startingLifePoints: lifePoints,
          ),
        );
    context.go(GamePage.routePath);
  }
}

class MatchHistoryPanel extends StatelessWidget {
  const MatchHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<AppBloc, AppState>(
      listener: (context, state) {
        // Reload match history when auth state changes
        context.read<MatchHistoryBloc>().add(
              LoadMatchHistory(userId: state.user.id),
            );
      },
      listenWhen: (previous, current) => previous.user != current.user,
      child: Column(
        children: [
          SectionHeader(title: l10n.matchHistoryTitle),
          Expanded(
            child: BlocBuilder<MatchHistoryBloc, MatchHistoryState>(
              builder: (context, state) {
                switch (state.status) {
                  case HomeStatus.initial:
                  case HomeStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case HomeStatus.failure:
                    return Center(
                      child: Text(l10n.matchHistoryLoadError),
                    );
                  case HomeStatus.success:
                    if (state.games.isEmpty) {
                      return Center(
                        child: Text(l10n.noMatchHistoryAvailable),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.games.length,
                      itemBuilder: (context, index) {
                        final game = state.games[index];
                        return CustomListItem(
                          wonGame: game.winner.firebaseId ==
                              context.read<AppBloc>().state.user.id,
                          thumbnail: game.winner.commander.imageUrl.isEmpty
                              ? Container(
                                  color: Color(game.winner.color)
                                      .withValues(alpha: .8),
                                )
                              : Image.network(
                                  fit: BoxFit.cover,
                                  game.winner.commander.imageUrl,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Color(game.winner.color)
                                        .withValues(alpha: .8),
                                  ),
                                ),
                          playerName: game.winner.name,
                          commanderName: game.winner.commander.name,
                          gameLength: Duration(seconds: game.durationInSeconds),
                          gameDatePlayed: game.endTime,
                          viewCount: index + 1,
                          textStyle: Theme.of(context).textTheme,
                          game: game,
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomListItem extends StatelessWidget {
  const CustomListItem({
    required this.thumbnail,
    required this.playerName,
    required this.commanderName,
    required this.gameLength,
    required this.gameDatePlayed,
    required this.viewCount,
    required this.textStyle,
    required this.wonGame,
    required this.game,
    super.key,
  });

  final Widget thumbnail;

  final String playerName;
  final bool wonGame;
  final String commanderName;
  final Duration gameLength;
  final DateTime gameDatePlayed;
  final int viewCount;
  final TextTheme textStyle;
  final GameModel game;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: wonGame
          ? AppColors.winner.withValues(alpha: .6)
          : AppColors.onSurfaceVariant,
      child: SizedBox(
        height: 160,
        child: Row(
          children: <Widget>[
            // Left section - Large thumbnail
            WinnerWidget(
              thumbnail: thumbnail,
              wentFirst: game.winner.id == game.startingPlayerId,
            ),
            const SizedBox(width: 5),
            // Middle section - Three stacked thumbnails
            LosersWidget(game: game),

            // Right section - Text information
            DetailsWidget(
              playerName: playerName,
              commanderName: commanderName,
              gameLength: gameLength,
              gameDatePlayed: gameDatePlayed,
              textStyle: textStyle,
              roomId: game.roomId,
            ),
          ],
        ),
      ),
    );
  }
}

class DetailsWidget extends StatelessWidget {
  const DetailsWidget({
    required this.playerName,
    required this.commanderName,
    required this.gameLength,
    required this.gameDatePlayed,
    required this.textStyle,
    required this.roomId,
    super.key,
  });

  final String playerName;
  final String commanderName;
  final Duration gameLength;
  final DateTime gameDatePlayed;
  final TextTheme textStyle;
  final String roomId;

  String _formatGameLength() {
    final hours = gameLength.inHours;
    final minutes = gameLength.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hr ${minutes} min';
    }
    return '$minutes min';
  }

  String _formatDate() {
    return '${gameDatePlayed.month}/${gameDatePlayed.day}/${gameDatePlayed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: textStyle.headlineMedium?.fontSize,
                  ),
                ),
                Text(
                  commanderName,
                  style: TextStyle(
                    fontSize: textStyle.titleMedium?.fontSize,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(
              ' ${l10n.gameId}: $roomId',
              style: textStyle.bodyLarge?.copyWith(
                color: AppColors.neutral60,
              ),
            ),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatGameLength(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LosersWidget extends StatelessWidget {
  const LosersWidget({
    required this.game,
    super.key,
  });

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    // Sort players by placement, excluding the winner (placement 1)
    final runnerUps = game.players
        .where((player) => player.placement > 1 && player.placement <= 4)
        .toList()
      ..sort((a, b) => a.placement.compareTo(b.placement));

    return SizedBox(
      width: 50,
      child: Column(
        children: [
          for (final player in runnerUps)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (player.commander.imageUrl.isEmpty)
                    Container(
                      color: Color(player.color).withValues(alpha: .8),
                    )
                  else
                    Image.network(
                      fit: BoxFit.cover,
                      player.commander.imageUrl,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Color(player.color).withValues(alpha: .8),
                      ),
                    ),
                  if (player.id == game.startingPlayerId)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.star,
                            size: 8,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class WinnerWidget extends StatelessWidget {
  const WinnerWidget({
    required this.thumbnail,
    required this.wentFirst,
    super.key,
  });

  final Widget thumbnail;
  final bool wentFirst;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            child: thumbnail,
          ),
          if (wentFirst)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.star,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
