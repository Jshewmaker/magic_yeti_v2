import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/view/game_page.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_tokens.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';

class GameOverHeader extends StatelessWidget {
  const GameOverHeader({
    required this.canRestoreGame,
    this.compact = false,
    super.key,
  });

  final bool canRestoreGame;

  /// Renders the restore control icon-only so the title keeps the full width.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 20,
        vertical: compact ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: GameOverTokens.border)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
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
          if (canRestoreGame)
            Align(
              alignment: Alignment.centerLeft,
              child: RestoreGameButton(compact: compact),
            ),
        ],
      ),
    );
  }
}

class RestoreGameButton extends StatelessWidget {
  const RestoreGameButton({this.compact = false, super.key});

  final bool compact;

  void _restore(BuildContext context) {
    final l10n = context.l10n;
    context.read<TimerBloc>().add(const TimerStartEvent());
    context.read<GameBloc>()
      ..add(const GameRestoreRequested())
      ..add(const GameResumeEvent());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.gameRestoredMessage)),
    );
    context.go(GamePage.routePath);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: () => _restore(context),
        color: GameOverTokens.textSecondary,
        tooltip: 'Restore game',
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
      );
    }

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
      onPressed: () => _restore(context),
    );
  }
}
