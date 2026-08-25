import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/view/game_page.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_tokens.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';

class GameOverHeader extends StatelessWidget {
  const GameOverHeader({required this.canRestoreGame, super.key});
  final bool canRestoreGame;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: GameOverTokens.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: canRestoreGame ? const RestoreGameButton() : null,
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                'MATCH COMPLETE',
                style: TextStyle(
                  color: GameOverTokens.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.l10n.gameOverTitle,
                style: const TextStyle(
                  color: GameOverTokens.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 140),
        ],
      ),
    );
  }
}

class RestoreGameButton extends StatelessWidget {
  const RestoreGameButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: GameOverTokens.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 13),
      label: const Text(
        'RESTORE GAME',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      onPressed: () {
        context.read<TimerBloc>().add(const TimerStartEvent());
        context.read<GameBloc>()
          ..add(const GameRestoreRequested())
          ..add(const GameResumeEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.gameRestoredMessage)),
        );
        context.go(GamePage.routePath);
      },
    );
  }
}
