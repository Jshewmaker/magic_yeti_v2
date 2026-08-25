import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_tokens.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:player_repository/player_repository.dart';

class GameOverWinnerHero extends StatelessWidget {
  const GameOverWinnerHero({
    required this.winner,
    this.compact = false,
    super.key,
  });

  final Player winner;

  /// Stacks the winner details above an inline duration instead of putting a
  /// boxed duration chip beside them. Phone layout.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasArt = winner.commander?.imageUrl.isNotEmpty ?? false;

    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 180 : 200,
        maxHeight: compact ? double.infinity : 200,
      ),
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
      // `passthrough` hands the content `Padding` below the exact
      // constraints this `Stack` itself received. For the tablet path those
      // constraints are already tight at 200 (identical to what `expand`
      // would produce), so tablet rendering is unaffected. For the compact
      // path the height constraint is only a floor (180) with no ceiling, so
      // the content drives the final height and the frame grows with it —
      // instead of clipping — when a wrapped name and a commander subtitle
      // don't fit in 180.
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Commander art and gradient scrim are `Positioned.fill` so they
          // always stretch to match the frame's *final* height, which for
          // the compact path is only known after the content below has been
          // measured.
          if (hasArt) ...[
            Positioned.fill(
              child: Image.network(
                winner.commander!.imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            // Gradient scrim
            Positioned.fill(
              child: Container(
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
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 18 : 28,
              vertical: 20,
            ),
            child: compact
                ? _CompactContent(winner: winner)
                : _WideContent(winner: winner),
          ),
        ],
      ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          color: GameOverTokens.gold,
          size: 18,
        ),
        const SizedBox(width: 7),
        Text(
          context.l10n.winner.toUpperCase(),
          style: const TextStyle(
            color: GameOverTokens.gold,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _CompactContent extends StatelessWidget {
  const _CompactContent({required this.winner});

  final Player winner;

  @override
  Widget build(BuildContext context) {
    final elapsed = context.watch<TimerBloc>().state.elapsedSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WinnerBanner(),
        const SizedBox(height: 6),
        Text(
          winner.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GameOverTokens.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        if (winner.commander?.name.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            winner.commander!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GameOverTokens.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              color: GameOverTokens.textSecondary,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              formatGameDuration(elapsed),
              style: const TextStyle(
                color: GameOverTokens.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WideContent extends StatelessWidget {
  const _WideContent({required this.winner});

  final Player winner;

  @override
  Widget build(BuildContext context) {
    final elapsed = context.watch<TimerBloc>().state.elapsedSeconds;
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WinnerBanner(),
              const SizedBox(height: 6),
              Text(
                winner.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GameOverTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
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
    );
  }
}

String formatGameDuration(int seconds) {
  final d = Duration(seconds: seconds);
  return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
}
