import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/view/game_page.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:player_repository/player_repository.dart';

// ─── Page ────────────────────────────────────────────────────────────────────
class GameOverPage extends StatelessWidget {
  const GameOverPage({super.key});

  factory GameOverPage.pageBuilder(Object _, Object _) =>
      const GameOverPage(key: Key('game_over_page'));

  static const routeName = 'game_over_page';
  static String get routePath => '/game_over_page';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameOverBloc(
        players: context.read<PlayerRepository>().getPlayers(),
        currentUserId: context.read<AppBloc>().state.user.id,
        firebaseDatabaseRepository: context.read<FirebaseDatabaseRepository>(),
      ),
      child: const GameOverView(),
    );
  }
}

// ─── View ────────────────────────────────────────────────────────────────────
class GameOverView extends StatelessWidget {
  const GameOverView({super.key});

  @override
  Widget build(BuildContext context) {
    final gameModel = context.watch<GameBloc>().state.gameModel;
    if (gameModel == null) {
      return const Scaffold(
        backgroundColor: GameOverTokens.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canRestoreGame = context.read<PlayerRepository>().canRestoreGame;
    final isPhone = DeviceInfoProvider.of(context).isPhone;

    return OrientationLock(
      orientations: isPhone ? const [DeviceOrientation.portraitUp] : null,
      child: Scaffold(
        backgroundColor: GameOverTokens.background,
        body: BlocListener<GameOverBloc, GameOverState>(
          listenWhen: (previous, current) =>
              previous.status != current.status,
          listener: (context, state) {
            switch (state.status) {
              case GameOverStatus.success:
                switch (state.exitIntent) {
                  case GameOverExitIntent.home:
                    context.go(HomePage.routeName);
                  case GameOverExitIntent.playAgain:
                    context.read<GameBloc>().add(const GameResetEvent());
                    context.read<TimerBloc>()
                      ..add(const TimerResetEvent())
                      ..add(const TimerStartEvent());
                    context.go(GamePage.routePath);
                }
              case GameOverStatus.failure:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.gameSaveFailedError)),
                );
              case GameOverStatus.initial:
              case GameOverStatus.loading:
                break;
            }
          },
          child: BlocBuilder<GameOverBloc, GameOverState>(
            builder: (context, state) {
              return AdaptiveLayout(
                phone: (_) => _PhoneShell(
                  state: state,
                  gameModel: gameModel,
                  canRestoreGame: canRestoreGame,
                ),
                tablet: (_) => _TabletShell(
                  state: state,
                  gameModel: gameModel,
                  canRestoreGame: canRestoreGame,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabletShell extends StatelessWidget {
  const _TabletShell({
    required this.state,
    required this.gameModel,
    required this.canRestoreGame,
  });

  final GameOverState state;
  final GameModel gameModel;
  final bool canRestoreGame;

  @override
  Widget build(BuildContext context) {
    final players = state.standings;

    return Column(
      children: [
        GameOverHeader(canRestoreGame: canRestoreGame),
        GameOverWinnerHero(winner: players.first),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: GameOverStandingsPanel(state: state),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: GameOverDetailsPanel(
                    state: state,
                    players: players,
                    gameModel: gameModel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneShell extends StatelessWidget {
  const _PhoneShell({
    required this.state,
    required this.gameModel,
    required this.canRestoreGame,
  });

  final GameOverState state;
  final GameModel gameModel;
  final bool canRestoreGame;

  @override
  Widget build(BuildContext context) {
    final players = state.standings;
    final userId = context.read<AppBloc>().state.user.id;
    final canSubmit = canSubmitGameOver(state);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      // The action bar's own Container fill takes over clearing the home
      // indicator (via bottomInset added to its padding below) so its
      // surface color runs flush to the screen edge instead of stopping
      // above a strip of the scaffold's darker background.
      bottom: false,
      child: Column(
        children: [
          GameOverHeader(canRestoreGame: canRestoreGame, compact: true),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GameOverWinnerHero(
                    winner: players.first,
                    compact: true,
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: GameOverSectionLabel(
                      label: 'FINAL STANDINGS',
                      trailing: Tooltip(
                        message: 'Drag to reorder',
                        waitDuration: Duration(milliseconds: 100),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: GameOverTokens.textSecondary,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverReorderableList(
                    itemCount: players.length,
                    proxyDecorator: standingsProxyDecorator(players),
                    onReorder: (oldIndex, newIndex) =>
                        onStandingsReorder(context, oldIndex, newIndex),
                    itemBuilder: standingsItemBuilder(players),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GameOverSectionLabel(label: 'MATCH DETAILS'),
                        const SizedBox(height: 14),
                        GameOverDetailsFields(
                          state: state,
                          players: players,
                          currentUserId: userId,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            key: const Key('game_over_phone_action_bar_container'),
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
            decoration: const BoxDecoration(
              color: GameOverTokens.surface,
              border: Border(top: BorderSide(color: GameOverTokens.border)),
            ),
            child: GameOverActionBar(
              canSubmit: canSubmit,
              stacked: true,
              onReturnHome: () => context.read<GameOverBloc>().add(
                SendGameOverStatsEvent(gameModel: gameModel, userId: userId),
              ),
              onPlayAgain: () => context.read<GameOverBloc>().add(
                SendGameOverStatsEvent(
                  gameModel: gameModel,
                  userId: userId,
                  exitIntent: GameOverExitIntent.playAgain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
