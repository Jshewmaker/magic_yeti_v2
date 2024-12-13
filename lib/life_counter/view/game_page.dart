import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/life_counter.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  factory GamePage.pageBuilder(_, __) {
    return const GamePage(
      key: Key('game_page'),
    );
  }

  static const routeName = 'game_page';
  static String get routePath => '/game_page';

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameBloc>().state;
    final playerCount = gameState.playerList.length;
    if (gameState.playerList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        if (playerCount == 2) const TwoPlayerGame() else const FourPlayerGame(),
        if (gameState.status == GameStatus.finished) const GameOverWidget(),
      ],
    );
  }
}
