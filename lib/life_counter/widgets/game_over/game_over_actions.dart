import 'package:flutter/material.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_tokens.dart';

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
