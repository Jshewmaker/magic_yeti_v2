import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/app/utils/device_info_provider.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/life_counter.dart';
import 'package:magic_yeti/login/login.dart';
import 'package:magic_yeti/match_details/view/match_details_page.dart';
import 'package:magic_yeti/profile/view/profile_page.dart';
import 'package:magic_yeti/sign_up/sign_up.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  factory HomePage.pageBuilder(_, __) {
    return const HomePage(key: Key('home_page'));
  }

  static const routeName = '/';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // Use DeviceInfoProvider instead of LayoutBuilder
    final isPhone = DeviceInfoProvider.of(context).isPhone;

    // Set preferred orientations for phones
    if (isPhone) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    return isPhone ? const _PhoneView() : const _TabletView();
  }
}

class _TabletView extends StatelessWidget {
  const _TabletView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Row(
        children: [
          const Expanded(child: LeftSidePanel()),
          Expanded(
            child: Column(
              children: [
                SectionHeader(title: l10n.matchHistoryTitle),
                const Expanded(
                  child: MatchHistoryPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: AppColors.white,
        backgroundColor: AppColors.tertiary,
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (BuildContext _) {
              String roomId = '';
              return AlertDialog(
                title: Text(l10n.addGameToHistoryTitle),
                content: TextField(
                  autocorrect: false,
                  onChanged: (value) {
                    roomId = value.toUpperCase();
                  },
                  decoration: InputDecoration(
                    hintText: l10n.enterRoomIdHint,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancelTextButton),
                  ),
                  TextButton(
                    onPressed: () {
                      if (roomId.isNotEmpty) {
                        context.read<MatchHistoryBloc>().add(
                              AddMatchToPlayerHistoryEvent(
                                roomId: roomId.toUpperCase(),
                                playerId: context.read<AppBloc>().state.user.id,
                              ),
                            );
                        Navigator.pop(context);
                      }
                    },
                    child: Text(l10n.addButtonText),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      resizeToAvoidBottomInset: false,
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
    final user = context.read<AppBloc>().state.user;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.quaternary,
        border: Border(
          right: BorderSide(width: 3, color: AppColors.background),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          if (onMorePressed != null)
            user.photo == null || user.photo!.isEmpty
                ? IconButton(
                    onPressed: onMorePressed,
                    icon: const Icon(
                      Icons.account_circle_sharp,
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                : InkWell(
                    onTap: onMorePressed,
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(user.photo!),
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
      children: [
        SectionHeader(title: l10n.gameModeTitle),
        GameModeButtons(l10n: l10n),
        SectionHeader(
          title: onMore ? l10n.statsTitle : 'Login/Sign Up',
          onMorePressed: onMore
              ? () {
                  context.go(ProfilePage.routePath);
                }
              : null,
        ),
        const AccountWidget(),
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

    final matchHistoryState = context.watch<MatchHistoryBloc>().state;
    final l10n = context.l10n;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: !userIsLoggedIn
            ? matchHistoryState.status ==
                    MatchHistoryStatus.loadingHistorySuccess
                ? StatsOverviewWidget(key: ObjectKey(matchHistoryState))
                : const CircularProgressIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 70,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: () => context.go(LoginPage.routeName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Center(
                        child: Text(
                          l10n.loginButtonText,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 70,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: () => context.go(SignUpPage.routeName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Center(
                        child: Text(
                          l10n.signUpAppBarTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
    // Check if we're on a phone by using MediaQuery

    // For phones, use a column layout instead of row
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 120, // Fixed height for both buttons
              child: ElevatedButton(
                onLongPress: () => _createGame(context, 2, 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.comingSoonText),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(
                    alpha: 0.1,
                  ),
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
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      l10n.underConstructionText,
                      style: TextStyle(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.construction,
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 120, // Same fixed height for consistency
              child: ElevatedButton(
                onPressed: () => _createGame(context, 4, 40),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(
                    alpha: 0.1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  l10n.numberOfPlayers(4),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
    final appState = context.watch<AppBloc>().state;

    if (appState.status != AppStatus.authenticated) {
      context.read<MatchHistoryBloc>().add(const ClearMatchHistory());
    } else {
      context
          .read<MatchHistoryBloc>()
          .add(LoadMatchHistory(userId: appState.user.id));
    }
    return BlocListener<MatchHistoryBloc, MatchHistoryState>(
      listener: (context, state) {
        if (state.status == MatchHistoryStatus.gameNotFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.tertiarySecondary,
              content: Center(
                child: Text(
                  l10n.gameNotFoundError,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.black,
                      ),
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: 20,
                right: 20,
                left: MediaQuery.of(context).size.width / 2,
              ),
            ),
          );
        }
      },
      child: BlocBuilder<MatchHistoryBloc, MatchHistoryState>(
        builder: (context, state) {
          switch (state.status) {
            case MatchHistoryStatus.initial:
            case MatchHistoryStatus.loadingHistory:
              return const Center(child: CircularProgressIndicator());
            case MatchHistoryStatus.failure:
              return Center(
                child: Text(l10n.matchHistoryLoadError),
              );
            case MatchHistoryStatus.gameNotFound:
            case MatchHistoryStatus.loadingHistorySuccess:
              if (state.games.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noMatchHistoryAvailable,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }
              return ListView.builder(
                itemCount: state.games.length,
                itemBuilder: (context, index) {
                  final game = state.games[index];
                  final winningPlayer = game.players.firstWhere(
                    (player) => player.id == game.winnerId,
                  );
                  return CustomListItem(
                    wonGame: winningPlayer.firebaseId ==
                        context.read<AppBloc>().state.user.id,
                    thumbnail: (winningPlayer.commander?.imageUrl.isEmpty ??
                            false)
                        ? Container(
                            color: Color(winningPlayer.color)
                                .withValues(alpha: .8),
                          )
                        : winningPlayer.partner?.imageUrl == null
                            ? Image.network(
                                fit: BoxFit.cover,
                                winningPlayer.commander?.imageUrl ?? '',
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Color(winningPlayer.color)
                                      .withValues(alpha: .8),
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Image.network(
                                      winningPlayer.commander?.imageUrl ?? '',
                                      fit: BoxFit.fitHeight,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Color(winningPlayer.color)
                                                .withValues(
                                              alpha:
                                                  winningPlayer.lifePoints <= 0
                                                      ? .3
                                                      : 1,
                                            ),
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(20),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: Image.network(
                                      winningPlayer.partner?.imageUrl ?? '',
                                      fit: BoxFit.fitHeight,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Color(winningPlayer.color)
                                                .withValues(
                                              alpha:
                                                  winningPlayer.lifePoints <= 0
                                                      ? .3
                                                      : 1,
                                            ),
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(20),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                    playerName: winningPlayer.name,
                    commanderName: winningPlayer.commander?.name ?? '',
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
    return InkWell(
      onTap: () {
        context.push(
          MatchDetailsPage.path(gameId: game.id!),
        );
      },
      child: Card(
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
                wentFirst: game.winnerId == game.startingPlayerId,
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
      return '$hours hr $minutes min';
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                    height: 0.9, // Reduce the line height
                  ),
                ),
                Text(
                  commanderName,
                  style: TextStyle(
                    fontSize: textStyle.titleMedium?.fontSize,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                    height: 0.9, // Reduce the line height
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ' ${l10n.gameId}: $roomId',
                  style: textStyle.labelLarge?.copyWith(
                    color: Colors.black45,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  color: Colors.black45,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomId));
                    showToast(
                      context,
                      Toast.success(message: '${l10n.copiedGameId}: $roomId'),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatGameLength(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
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
                  if (player.commander?.imageUrl.isEmpty ?? false)
                    Container(
                      color: Color(player.color).withValues(alpha: .8),
                    )
                  else
                    player.partner?.imageUrl == null
                        ? Image.network(
                            fit: BoxFit.cover,
                            player.commander?.imageUrl ?? '',
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color:
                                    Color(player.color).withValues(alpha: .8),
                              );
                            },
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Image.network(
                                  player.commander?.imageUrl ?? '',
                                  fit: BoxFit.fitHeight,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Color(player.color).withValues(
                                          alpha:
                                              player.lifePoints <= 0 ? .3 : 1,
                                        ),
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(20),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: Image.network(
                                  player.partner?.imageUrl ?? '',
                                  fit: BoxFit.fitHeight,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Color(player.color).withValues(
                                          alpha:
                                              player.lifePoints <= 0 ? .3 : 1,
                                        ),
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(20),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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

class _PhoneView extends StatelessWidget {
  const _PhoneView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.quaternary,
          title: Text(
            'Magic Yeti',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.gameModeTitle),
              Tab(text: l10n.matchHistoryTitle),
            ],
            indicatorColor: AppColors.tertiary,
            labelColor: AppColors.onSurfaceVariant,
          ),
        ),
        body: const TabBarView(
          children: [
            PhoneLeftSidePanel(),
            MatchHistoryPanel(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          foregroundColor: AppColors.white,
          backgroundColor: AppColors.tertiary,
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (BuildContext _) {
                String roomId = '';
                return AlertDialog(
                  title: Text(l10n.addGameToHistoryTitle),
                  content: TextField(
                    autocorrect: false,
                    onChanged: (value) {
                      roomId = value.toUpperCase();
                    },
                    decoration: InputDecoration(
                      hintText: l10n.enterRoomIdHint,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancelTextButton),
                    ),
                    TextButton(
                      onPressed: () {
                        if (roomId.isNotEmpty) {
                          context.read<MatchHistoryBloc>().add(
                                AddMatchToPlayerHistoryEvent(
                                  roomId: roomId.toUpperCase(),
                                  playerId:
                                      context.read<AppBloc>().state.user.id,
                                ),
                              );
                          Navigator.pop(context);
                        }
                      },
                      child: Text(l10n.addButtonText),
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.add),
        ),
        resizeToAvoidBottomInset: false,
      ),
    );
  }
}

class PhoneLeftSidePanel extends StatelessWidget {
  const PhoneLeftSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onMore =
        context.watch<AppBloc>().state.status == AppStatus.authenticated;
    return Column(
      children: [
        // GameMode section - Reduced padding
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GameModeButtons(l10n: l10n),
        ),
        // Account section with compact design
        SectionHeader(
          title: onMore ? l10n.statsTitle : l10n.loginSignUpTitle,
          onMorePressed: onMore
              ? () {
                  context.go(ProfilePage.routePath);
                }
              : null,
        ),
        const AccountWidget(),
      ],
    );
  }
}
