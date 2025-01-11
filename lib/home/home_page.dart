import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/bloc/home_bloc.dart';
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
    return const HomeView();
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
  });
  final String title;

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
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class LeftSidePanel extends StatelessWidget {
  const LeftSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Game Mode'),
        Expanded(
          child: GameModeButtons(l10n: l10n),
        ),
        const Expanded(
          child: Column(
            children: [
              SectionHeader(title: 'Your Stats'),
              AccountWidget(),
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
            ElevatedButton(
              onPressed: () =>
                  context.read<AppBloc>().add(const AppLogoutRequested()),
              child: Text(l10n.logOutButtonText),
            )
          else ...[
            ElevatedButton(
              onPressed: () => context.push(LoginPage.routeName),
              child: Text(l10n.loginButtonText),
            ),
            ElevatedButton(
              onPressed: () => context.push(SignUpPage.routeName),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => _createGame(context, 2, 20),
          child: Text(l10n.numberOfPlayers(2)),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _createGame(context, 4, 40),
          child: Text(l10n.numberOfPlayers(4)),
        ),
      ],
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
    return BlocProvider(
      create: (context) => HomeBloc(
        databaseRepository: context.read<FirebaseDatabaseRepository>(),
      )..add(const LoadMatchHistory()),
      child: Column(
        children: [
          const SectionHeader(title: 'Match History'),
          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                switch (state.status) {
                  case HomeStatus.initial:
                  case HomeStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case HomeStatus.failure:
                    return Center(
                      child:
                          Text(state.error ?? 'Failed to load match history'),
                    );
                  case HomeStatus.success:
                    if (state.games.isEmpty) {
                      return const Center(
                        child: Text('No match history available'),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.games.length,
                      itemBuilder: (context, index) {
                        final game = state.games[index];
                        return CustomListItem(
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
    required this.game,
    super.key,
  });

  final Widget thumbnail;
  final String playerName;
  final String commanderName;
  final Duration gameLength;
  final DateTime gameDatePlayed;
  final int viewCount;
  final TextTheme textStyle;
  final GameModel game;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 120,
        child: Row(
          children: <Widget>[
            // Left section - Large thumbnail
            WinnerWidget(thumbnail: thumbnail),
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
    super.key,
  });

  final String playerName;
  final String commanderName;
  final Duration gameLength;
  final DateTime gameDatePlayed;
  final TextTheme textStyle;

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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                const SizedBox(height: 4),
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
      width: 40,
      child: Column(
        children: [
          for (final player in runnerUps)
            Expanded(
              child: player.commander.imageUrl.isEmpty
                  ? Container(
                      color: Color(player.color).withValues(alpha: .8),
                    )
                  : Image.network(
                      fit: BoxFit.cover,
                      player.commander.imageUrl,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Color(player.color).withValues(alpha: .8),
                      ),
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
    super.key,
  });

  final Widget thumbnail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        child: thumbnail,
      ),
    );
  }
}
