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
            buildDefaultDragHandles: false,
            proxyDecorator: standingsProxyDecorator(state.standings),
            itemCount: state.standings.length,
            onReorder: (oldIndex, newIndex) =>
                onStandingsReorder(context, oldIndex, newIndex),
            itemBuilder: standingsItemBuilder(state.standings),
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
    this.dragIndex,
    super.key,
  });

  final Player player;
  final int placement;

  /// Index this row occupies in the surrounding reorderable list. When set,
  /// the grip becomes the only thing that starts a drag, leaving the rest of
  /// the row free to scroll the page. Null inside `proxyDecorator`, which
  /// renders outside the reorderable's scope.
  final int? dragIndex;

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
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GameOverTokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (player.commander?.name.isNotEmpty ?? false)
                      Text(
                        player.commander!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              _DragHandle(dragIndex: dragIndex),
            ],
          ),
        ],
      ),
    );
  }
}

/// Builds the floating-row animation used while a [StandingRow] is being
/// dragged. Shared by the tablet standings panel and the phone shell so both
/// reorderable lists look the same mid-drag.
ReorderItemProxyDecorator standingsProxyDecorator(List<Player> standings) {
  return (child, index, animation) {
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
            player: standings[index],
            placement: index + 1,
          ),
        );
      },
    );
  };
}

/// Builds the itemBuilder used by both the tablet's [ReorderableListView]
/// and the phone's [SliverReorderableList] so both reorderable lists render
/// rows identically.
Widget Function(BuildContext, int) standingsItemBuilder(
  List<Player> standings,
) {
  return (context, index) => StandingRow(
    key: ValueKey(standings[index].id),
    player: standings[index],
    placement: index + 1,
    dragIndex: index,
  );
}

/// Dispatches a standings reorder straight through to [GameOverBloc].
///
/// [SliverReorderableList.onReorder] and [ReorderableListView.onReorder]
/// share the same oldIndex/newIndex convention, and
/// `GameOverBloc._onUpdateStandings` already does the newIndex-1 adjustment
/// for a forward move — dispatch the raw indices here. Adjusting again
/// would silently corrupt the resulting order with no crash.
void onStandingsReorder(BuildContext context, int oldIndex, int newIndex) {
  context.read<GameOverBloc>().add(
    UpdateStandingsEvent(oldIndex: oldIndex, newIndex: newIndex),
  );
}

/// A small uppercase, letter-spaced section label used to head panels in the
/// game-over layout, with an optional trailing widget (e.g. an info icon).
class GameOverSectionLabel extends StatelessWidget {
  const GameOverSectionLabel({required this.label, this.trailing, super.key});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GameOverTokens.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.dragIndex});

  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    const handle = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Icon(
        Icons.drag_handle_rounded,
        color: GameOverTokens.textSecondary,
        size: 20,
      ),
    );

    final index = dragIndex;
    if (index == null) return handle;

    return ReorderableDragStartListener(index: index, child: handle);
  }
}
