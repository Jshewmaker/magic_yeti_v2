import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
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

  factory GameOverPage.pageBuilder(Object _, Object __) =>
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

    return Scaffold(
      backgroundColor: GameOverTokens.background,
      body: BlocListener<GameOverBloc, GameOverState>(
        listenWhen: (previous, current) => previous.status != current.status,
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
            final players = state.standings;
            final winner = players.first;

            return Column(
              children: [
                GameOverHeader(canRestoreGame: canRestoreGame),
                GameOverWinnerHero(winner: winner),
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
          },
        ),
      ),
    );
  }
}
