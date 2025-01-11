import 'dart:async';
import 'dart:math';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
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
    return Column(
      children: [
        const SectionHeader(title: 'Match History'),
        Expanded(
          child: ListView.builder(
            itemCount: 20,
            itemBuilder: (context, index) {
              return CustomListItem(
                thumbnail: Image.network(
                  fit: BoxFit.cover,
                  commanderList[Random().nextInt(commanderList.length)],
                ),
                playerName: players[Random().nextInt(players.length)],
                commanderName:
                    'Rin & Seri, Inseparable', // Using the example commander
                gameLength: const Duration(minutes: 92), // 1:32:00 in minutes
                gameDatePlayed: DateTime.now(),
                viewCount: index + 1,
                textStyle: Theme.of(context).textTheme,
              );
            },
          ),
        ),
      ],
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
    super.key,
  });

  final Widget thumbnail;
  final String playerName;
  final String commanderName;
  final Duration gameLength;
  final DateTime gameDatePlayed;
  final int viewCount;
  final TextTheme textStyle;

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
            const LosersWidget(),

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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          Expanded(
            child: Image.network(
              fit: BoxFit.cover,
              commanderList[Random().nextInt(commanderList.length)],
            ),
          ),
          Expanded(
            child: Image.network(
              fit: BoxFit.cover,
              commanderList[Random().nextInt(commanderList.length)],
            ),
          ),
          Expanded(
            child: Image.network(
              fit: BoxFit.cover,
              commanderList[Random().nextInt(commanderList.length)],
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

final List<String> commanderList = [
  'https://cards.scryfall.io/art_crop/front/d/6/d67be074-cdd4-41d9-ac89-0a0456c4e4b2.jpg?1674057568',
  'https://cards.scryfall.io/art_crop/front/0/6/066c8f63-52e6-475e-8d27-6ee37e92fc05.jpg?1591234280',
  'https://cards.scryfall.io/art_crop/front/2/1/213e530e-33a9-4358-b43b-4a276a7e7190.jpg?1674140675',
  'https://cards.scryfall.io/art_crop/front/e/a/ea476ee1-67d9-4dd8-a5ac-f68a155eb18b.jpg?1624740590',
  'https://cards.scryfall.io/art_crop/front/a/e/ae9231fd-053d-4b84-a7a8-86063465bc49.jpg?1692939339',
  'https://cards.scryfall.io/art_crop/front/d/6/d605c780-a42a-4816-8fb9-63e3114a8246.jpg?1677724018',
  'https://cards.scryfall.io/art_crop/front/0/1/01f40e07-f565-4b9e-87a5-5b28b4e9fb0b.jpg?1696636767',
  'https://cards.scryfall.io/art_crop/front/4/2/42bbedc1-6b83-46b4-8b3b-a4e05ce77d87.jpg?1721428140',
  'https://cards.scryfall.io/art_crop/front/3/d/3d6d6944-a364-41c2-b824-7a1bf6ad0d1e.jpg?1710673435',
  'https://cards.scryfall.io/art_crop/front/1/0/10d42b35-844f-4a64-9981-c6118d45e826.jpg?1689999317',
  'https://cards.scryfall.io/art_crop/front/8/d/8d7c1f6c-af45-4449-8cf8-e13830b3df8a.jpg?1726596807',
  'https://cards.scryfall.io/art_crop/front/a/5/a577ba08-0aa8-45be-aa83-d5078770127c.jpg?1729893416',
  'https://cards.scryfall.io/art_crop/front/f/6/f683d5a1-b8bf-446f-9fe3-88a4398bf3cf.jpg?1726286645',
];

final List<String> players = [
  'Joshua',
  'Wilson',
  'Nick',
  'Luke',
  'Scotty',
  'Brendan',
];
