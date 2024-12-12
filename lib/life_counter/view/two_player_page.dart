import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/tracker/tracker.dart';
import 'package:player_repository/player_repository.dart';

class TwoPlayerPage extends StatelessWidget {
  const TwoPlayerPage({super.key});

  static const String routePath = '/two-player';

  static Widget pageBuilder(BuildContext context, dynamic state) =>
      const TwoPlayerPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: TwoPlayerView(),
    );
  }
}

class TwoPlayerView extends StatelessWidget {
  const TwoPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerList = context.read<GameBloc>().state.playerList;
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.portrait) {
      return Column(
        children: [
          Expanded(
            child: _PlayerSection(
              playerId: playerList[1].id,
              rotate: true,
            ),
          ),
          const RotatedBox(quarterTurns: 3, child: _CenterControlColumn()),
          Expanded(
            child: _PlayerSection(
              playerId: playerList[0].id,
              rotate: false,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _PlayerColumn(
              topPlayerId: playerList[1].id,
              bottomPlayerId: playerList[0].id,
              isTop: true,
            ),
          ),
          const _CenterControlColumn(),
        ],
      );
    }
  }
}

class _PlayerColumn extends StatelessWidget {
  const _PlayerColumn({
    required this.topPlayerId,
    required this.bottomPlayerId,
    this.isTop = true,
  });

  final String topPlayerId;
  final String bottomPlayerId;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _PlayerSection(
            playerId: topPlayerId,
            rotate: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: _PlayerSection(
            playerId: bottomPlayerId,
            rotate: false,
          ),
        ),
      ],
    );
  }
}

class _PlayerSection extends StatelessWidget {
  const _PlayerSection({
    required this.playerId,
    required this.rotate,
    this.alignment,
  });

  final String playerId;
  final bool rotate;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc(
        playerRepository: context.read<PlayerRepository>(),
        playerId: playerId,
      ),
      child: Stack(
        alignment: alignment ?? Alignment.topLeft,
        children: [
          LifeCounterWidget(
            rotate: rotate,
          ),
          TrackerWidgets(
            rotate: !rotate,
            playerId: playerId,
          ),
        ],
      ),
    );
  }
}

class _CenterControlColumn extends StatelessWidget {
  const _CenterControlColumn();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      color: Colors.black26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              context.read<GameBloc>().add(const GameResetEvent());
            },
            icon: const Icon(
              Icons.refresh,
              color: AppColors.neutral60,
              size: 50,
            ),
          ),
          const TimerWidget(),
        ],
      ),
    );
  }
}
