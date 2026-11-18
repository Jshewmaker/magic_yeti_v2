import 'package:flutter/material.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_tokens.dart';

/// Whether the game-over form has everything it needs to submit.
///
/// This really belongs on [GameOverState] itself, but this branch's
/// no-bloc-changes constraint rules that out — it lives here instead of
/// being computed separately by each shell/panel that needs it.
bool canSubmitGameOver(GameOverState state) =>
    state.selectedPlayerId != null &&
    state.firstPlayerId != null &&
    state.status != GameOverStatus.loading;

class GameOverActionButton extends StatelessWidget {
  const GameOverActionButton({
    required this.label,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 12,
      letterSpacing: 0.5,
    );

    if (isPrimary) {
      return ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: GameOverTokens.accent,
          disabledBackgroundColor: GameOverTokens.border,
          foregroundColor: Colors.white,
          disabledForegroundColor: GameOverTokens.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(label, style: labelStyle),
      );
    }

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled
            ? GameOverTokens.textPrimary
            : GameOverTokens.textSecondary,
        side: BorderSide(
          color: enabled
              ? GameOverTokens.border
              : GameOverTokens.border.withValues(alpha: 0.4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label, style: labelStyle),
    );
  }
}

class GameOverRequiredHint extends StatelessWidget {
  const GameOverRequiredHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          color: GameOverTokens.textSecondary,
          size: 13,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Fill out both fields to continue',
            style: TextStyle(
              color: GameOverTokens.textSecondary.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class GameOverActionBar extends StatelessWidget {
  const GameOverActionBar({
    required this.canSubmit,
    required this.onReturnHome,
    required this.onPlayAgain,
    this.stacked = false,
    super.key,
  });

  final bool canSubmit;
  final VoidCallback onReturnHome;
  final VoidCallback onPlayAgain;

  /// Full-width buttons in a column. `RETURN TO HOME` needs ~126pt and a
  /// side-by-side phone layout leaves ~134pt, which breaks at larger text
  /// scales or in translation.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final playAgain = GameOverActionButton(
      label: l10n.playAgain,
      isPrimary: true,
      enabled: canSubmit,
      onPressed: onPlayAgain,
    );
    final returnHome = GameOverActionButton(
      label: l10n.returnToHome,
      isPrimary: false,
      enabled: canSubmit,
      onPressed: onReturnHome,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!canSubmit) ...[
          const GameOverRequiredHint(),
          const SizedBox(height: 12),
        ],
        if (stacked) ...[
          playAgain,
          const SizedBox(height: 10),
          returnHome,
        ] else
          Row(
            children: [
              Expanded(child: returnHome),
              const SizedBox(width: 10),
              Expanded(child: playAgain),
            ],
          ),
      ],
    );
  }
}
