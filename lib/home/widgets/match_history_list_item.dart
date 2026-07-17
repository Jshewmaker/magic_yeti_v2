import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/match_details/view/match_details_page.dart';
import 'package:player_repository/models/player.dart';

/// A single game in the match history list: winner art, runner-up art, and
/// the game's details. Tapping opens the match details page.
class MatchHistoryListItem extends StatelessWidget {
  const MatchHistoryListItem({required this.game, super.key});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final winningPlayer = game.players.firstWhere(
      (player) => player.id == game.winnerId,
    );
    final wonGame =
        winningPlayer.firebaseId == context.read<AppBloc>().state.user.id;

    return InkWell(
      onTap: () async {
        await context.push(
          MatchDetailsPage.path(gameId: game.id!),
        );
      },
      child: Card(
        color: wonGame
            ? AppColors.winner.withValues(alpha: .6)
            : AppColors.tertiary,
        child: SizedBox(
          height: 160,
          child: Row(
            children: [
              _WinnerArt(
                player: winningPlayer,
                wentFirst: game.winnerId == game.startingPlayerId,
              ),
              const SizedBox(width: 5),
              _RunnerUpsArt(game: game),
              _GameDetails(
                winner: winningPlayer,
                game: game,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The commander (and partner, when present) artwork for [player], falling
/// back to the player's color when no artwork is available.
class CommanderArtThumbnail extends StatelessWidget {
  const CommanderArtThumbnail({required this.player, super.key});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final commanderUrl = player.commander?.imageUrl ?? '';
    final partnerUrl = player.partner?.imageUrl;

    if (commanderUrl.isEmpty) return _fallback();

    if (partnerUrl == null) {
      return Image.network(
        commanderUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final url in [commanderUrl, partnerUrl])
          Expanded(
            child: Image.network(
              url,
              fit: BoxFit.fitHeight,
              errorBuilder: (context, error, stackTrace) => _fallback(),
            ),
          ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      color: Color(player.color).withValues(alpha: .8),
    );
  }
}

/// Badge marking the player who took the first turn.
class _WentFirstBadge extends StatelessWidget {
  const _WentFirstBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.star,
          size: size * 2 / 3,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _WinnerArt extends StatelessWidget {
  const _WinnerArt({required this.player, required this.wentFirst});

  final Player player;
  final bool wentFirst;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            child: CommanderArtThumbnail(player: player),
          ),
          if (wentFirst)
            const Positioned(
              top: 8,
              right: 8,
              child: _WentFirstBadge(size: 24),
            ),
        ],
      ),
    );
  }
}

class _RunnerUpsArt extends StatelessWidget {
  const _RunnerUpsArt({required this.game});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    // Sort players by placement, excluding the winner (placement 1)
    final runnerUps =
        game.players
            .where((player) => player.placement > 1 && player.placement <= 4)
            .toList()
          ..sort((a, b) => a.placement.compareTo(b.placement));

    return SizedBox(
      width: 50,
      child: Column(
        children: [
          for (final player in runnerUps)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CommanderArtThumbnail(player: player),
                  if (player.id == game.startingPlayerId)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: _WentFirstBadge(size: 12),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GameDetails extends StatelessWidget {
  const _GameDetails({required this.winner, required this.game});

  final Player winner;
  final GameModel game;

  String _formatGameLength() {
    final gameLength = Duration(seconds: game.durationInSeconds);
    final hours = gameLength.inHours;
    final minutes = gameLength.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    return '$minutes min';
  }

  String _formatDate() {
    final date = game.endTime;
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textStyle = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  winner.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: textStyle.headlineSmall?.fontSize,
                    height: 0.9, // Reduce the line height
                  ),
                ),
                Text(
                  winner.commander?.name ?? '',
                  style: TextStyle(
                    fontSize: textStyle.titleMedium?.fontSize,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  ' ${l10n.gameId}: ${game.roomId}',
                  style: textStyle.labelLarge?.copyWith(
                    color: Colors.black45,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  color: Colors.black45,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: game.roomId));
                    showToast(
                      context,
                      Toast.success(
                        message: '${l10n.copiedGameId}: ${game.roomId}',
                      ),
                    );
                  },
                ),
              ],
            ),
            _IconDetailRow(
              icon: Icons.timer_outlined,
              text: _formatGameLength(),
            ),
            _IconDetailRow(
              icon: Icons.calendar_today,
              text: _formatDate(),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconDetailRow extends StatelessWidget {
  const _IconDetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
