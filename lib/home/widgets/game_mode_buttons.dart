import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/life_counter.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The "start a game" buttons shown on the home screen.
class GameModeButtons extends StatelessWidget {
  const GameModeButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                // Scale down instead of overflowing the fixed-height button
                // when text renders large (accessibility scales, wide fonts).
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.numberOfPlayers(2),
                        style: Theme.of(context).textTheme.headlineSmall
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

    context.read<TimerBloc>().add(const TimerStartEvent());
    context.go(GamePage.routePath);
  }
}
