import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_tokens.dart';
import 'package:player_repository/player_repository.dart';

class GameOverStandingsPanel extends StatelessWidget {
  const GameOverStandingsPanel({required this.state, super.key});
  final GameOverState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameOverTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameOverTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'FINAL STANDINGS',
                style: TextStyle(
                  color: GameOverTokens.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              SizedBox(width: 8),
              Tooltip(
                message: 'Drag to reorder',
                waitDuration: Duration(milliseconds: 100),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: GameOverTokens.textSecondary,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final scale = lerpDouble(
                    1,
                    1.02,
                    Curves.easeInOut.transform(animation.value),
                  )!;
                  return Transform.scale(
                    scale: scale,
                    child: StandingRow(
                      key: ValueKey('proxy_$index'),
                      player: state.standings[index],
                      placement: index + 1,
                    ),
                  );
                },
              );
            },
            itemCount: state.standings.length,
            onReorder: (oldIndex, newIndex) {
              context.read<GameOverBloc>().add(
                UpdateStandingsEvent(
                  oldIndex: oldIndex,
                  newIndex: newIndex,
                ),
              );
            },
            itemBuilder: (context, index) {
              final player = state.standings[index];
              return StandingRow(
                key: ValueKey(player.id),
                player: player,
                placement: index + 1,
              );
            },
          ),
        ],
      ),
    );
  }
}

class StandingRow extends StatelessWidget {
  const StandingRow({
    required this.player,
    required this.placement,
    super.key,
  });

  final Player player;
  final int placement;

  @override
  Widget build(BuildContext context) {
    final color = GameOverTokens.placementColor(placement);
    final hasArt = player.commander?.imageUrl.isNotEmpty ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 90,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: GameOverTokens.surfaceRaised,
        border: Border.all(
          color: placement == 1
              ? GameOverTokens.gold.withValues(alpha: 0.3)
              : GameOverTokens.border,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Commander art as subtle background
          if (hasArt)
            Opacity(
              opacity: 0.2,
              child: Image.network(
                player.commander!.imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

          Row(
            children: [
              // Placement color bar
              Container(width: 4, color: color),
              const SizedBox(width: 14),

              // Placement label
              SizedBox(
                width: 36,
                child: Text(
                  GameOverTokens.placementLabel(placement),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // Player + commander name
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        color: GameOverTokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (player.commander?.name.isNotEmpty ?? false)
                      Text(
                        player.commander!.name,
                        style: const TextStyle(
                          color: GameOverTokens.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),

              if (player.firebaseId != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: context.l10n.linkedAccountBadge,
                    child: const Icon(
                      Icons.link_rounded,
                      color: GameOverTokens.accent,
                      size: 16,
                    ),
                  ),
                ),

              // Drag handle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: GameOverTokens.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
