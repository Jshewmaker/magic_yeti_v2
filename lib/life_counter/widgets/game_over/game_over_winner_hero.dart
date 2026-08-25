import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_tokens.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:player_repository/player_repository.dart';

class GameOverWinnerHero extends StatelessWidget {
  const GameOverWinnerHero({required this.winner, super.key});
  final Player winner;

  @override
  Widget build(BuildContext context) {
    final elapsed = context.watch<TimerBloc>().state.elapsedSeconds;
    final l10n = context.l10n;
    final hasArt = winner.commander?.imageUrl.isNotEmpty ?? false;

    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: GameOverTokens.surfaceRaised,
        border: Border.all(
          color: GameOverTokens.gold.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Commander art
          if (hasArt) ...[
            Image.network(
              winner.commander!.imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            // Gradient scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],

          // Gold left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [GameOverTokens.gold, Color(0x44FFB020)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Row(
              // crossAxisAlignment defaults to center
              children: [
                // Winner info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: GameOverTokens.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            l10n.winner.toUpperCase(),
                            style: const TextStyle(
                              color: GameOverTokens.gold,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        winner.name,
                        style: const TextStyle(
                          color: GameOverTokens.textPrimary,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (winner.commander?.name.isNotEmpty ?? false) ...[
                        const SizedBox(height: 5),
                        Text(
                          winner.commander!.name,
                          style: const TextStyle(
                            color: GameOverTokens.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Duration chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GameOverTokens.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.gameDuration.toUpperCase(),
                        style: const TextStyle(
                          color: GameOverTokens.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatGameDuration(elapsed),
                        style: const TextStyle(
                          color: GameOverTokens.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
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

String formatGameDuration(int seconds) {
  final d = Duration(seconds: seconds);
  return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
}
