import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:player_repository/models/models.dart';

class CommanderDamageTracker extends StatefulWidget {
  const CommanderDamageTracker({
    required this.playerId,
    required this.player,
    required this.commanderPlayerId,
    super.key,
  });

  final String playerId;
  final String commanderPlayerId;
  final Player player;

  @override
  State<CommanderDamageTracker> createState() => _CommanderDamageTrackerState();
}

class _CommanderDamageTrackerState extends State<CommanderDamageTracker> {
  /// Builds the commander damage tracker widget with proper state management.
  ///
  /// This implementation uses a specialized selector pattern to ensure the widget
  /// rebuilds correctly when nested state changes occur. Here's why this is necessary:
  ///
  /// 1. The Problem:
  ///    - When using lists in Dart, modifying list contents doesn't change the list reference
  ///    - Simple selectors only detect reference changes, not content changes
  ///    - This means changes to damage amounts wouldn't trigger rebuilds
  ///
  /// 2. The Solution:
  ///    - We create a tuple containing both the opponent and their damage amounts
  ///    - By including damage amounts as a separate list, we force Flutter to compare values
  ///    - Any change to damage amounts creates a new list, triggering a rebuild
  ///
  /// 3. Performance:
  ///    - This approach is efficient as it only rebuilds when damage values actually change
  ///    - The map operation on damages is lightweight and only runs during selection
  ///
  /// This widget will rebuild when:
  ///   - Commander damage changes
  ///   - Partner damage changes
  ///   - The opponent's commander changes
  ///   - The opponent's partner changes
  @override
  Widget build(BuildContext context) {
    // Watch for changes in the opponent's damage by including the damage amounts
    // in the selector
    final opponent = context.select<PlayerBloc, (Opponent, List<int>)>(
      (bloc) {
        final opp = bloc.state.player.opponents!.firstWhere(
          (opponent) => opponent.playerId == widget.commanderPlayerId,
        );
        // Include damage amounts in the selector to force rebuild when they change
        final damageAmounts = opp.damages.map((d) => d.amount).toList();
        return (opp, damageAmounts);
      },
    ).$1;

    // Watch for changes in the commander and partner of the target player
    final targetPlayer = context.select<GameBloc, Player>(
      (bloc) => bloc.state.playerList.firstWhere(
        (player) => player.id == widget.commanderPlayerId,
      ),
    );

    final damageMap =
        opponent.damages.fold<Map<DamageType, int>>({}, (map, damage) {
      map[damage.damageType] = damage.amount;
      return map;
    });

    final commanderDamage = damageMap[DamageType.commander];
    final partnerDamage = damageMap[DamageType.partner];

    return targetPlayer.partner?.imageUrl.isNotEmpty ?? false
        ? Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Color(targetPlayer.color).withValues(alpha: 1),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    CommanderDamageButton(
                      playerId: widget.playerId,
                      commanderPlayerId: widget.commanderPlayerId,
                      player: widget.player,
                      targetPlayer: targetPlayer,
                      commanderDamage: commanderDamage ?? 0,
                      damageType: DamageType.commander,
                    ),
                    CommanderDamageButton(
                      playerId: widget.playerId,
                      commanderPlayerId: widget.commanderPlayerId,
                      player: widget.player,
                      targetPlayer: targetPlayer,
                      commanderDamage: partnerDamage ?? 0,
                      damageType: DamageType.partner,
                    ),
                  ],
                ),
              ),
            ),
          )
        : CommanderDamageButton(
            playerId: widget.playerId,
            commanderPlayerId: widget.commanderPlayerId,
            player: widget.player,
            targetPlayer: targetPlayer,
            commanderDamage: commanderDamage ?? 0,
            damageType: DamageType.commander,
          );
  }
}

class CommanderDamageButton extends StatefulWidget {
  const CommanderDamageButton({
    required this.playerId,
    required this.commanderPlayerId,
    required this.player,
    required this.targetPlayer,
    required this.commanderDamage,
    required this.damageType,
    super.key,
  });

  final String playerId;
  final String commanderPlayerId;
  final Player player;
  final Player targetPlayer;
  final int commanderDamage;
  final DamageType damageType;

  @override
  State<CommanderDamageButton> createState() => _CommanderDamageButtonState();
}

class _CommanderDamageButtonState extends State<CommanderDamageButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  static const double _defaultSize = 80;
  static const double _expandedSize = 140;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapOutside() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => _handleTapOutside(),
      child: GestureDetector(
        onTap: () {
          if (!_animationController.isCompleted) {
            context.read<PlayerBloc>().add(
                  UpdatePlayerLifeEvent(
                    decrement: true,
                    playerId: widget.playerId,
                  ),
                );
            context.read<PlayerBloc>().add(
                  PlayerCommanderDamageIncremented(
                    commanderId: widget.commanderPlayerId,
                    damageType: widget.damageType,
                  ),
                );
          }
        },
        onLongPressStart: (details) {
          if (!_animationController.isCompleted) {
            _animationController.forward();
          }
        },
        onLongPressDown: (details) {
          if (_animationController.isCompleted) {
            final box = context.findRenderObject()! as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final isTopHalf = localPosition.dy < box.size.height / 2;

            if (isTopHalf) {
              context.read<PlayerBloc>().add(
                    UpdatePlayerLifeEvent(
                      decrement: true,
                      playerId: widget.playerId,
                    ),
                  );
              context.read<PlayerBloc>().add(
                    PlayerCommanderDamageIncremented(
                      commanderId: widget.commanderPlayerId,
                      damageType: widget.damageType,
                    ),
                  );
            } else {
              context.read<PlayerBloc>().add(
                    UpdatePlayerLifeEvent(
                      decrement: false,
                      playerId: widget.playerId,
                    ),
                  );
              context.read<PlayerBloc>().add(
                    PlayerCommanderDamageDecremented(
                      commanderId: widget.commanderPlayerId,
                      damageType: widget.damageType,
                    ),
                  );
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width:
              _animationController.isCompleted ? _expandedSize : _defaultSize,
          height:
              _animationController.isCompleted ? _expandedSize : _defaultSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.damageType == DamageType.commander)
                _CommanderImage(
                  targetPlayer: widget.targetPlayer,
                  scale: _animationController.isCompleted
                      ? _expandedSize
                      : _defaultSize,
                  playerColor: widget.player.color,
                )
              else
                _PartnerImage(
                  targetPlayer: widget.targetPlayer,
                  scale: _animationController.isCompleted
                      ? _expandedSize
                      : _defaultSize,
                  playerColor: widget.player.color,
                ),
              _CommanderIcons(animationController: _animationController),
              StrokeText(
                text: widget.commanderDamage.toString(),
                fontSize: 28,
                color: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommanderImage extends StatelessWidget {
  const _CommanderImage({
    required this.targetPlayer,
    required this.scale,
    required this.playerColor,
  });
  final Player targetPlayer;
  final double scale;
  final int playerColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: targetPlayer.commander?.imageUrl.isEmpty ?? true
          ? Container(
              color: Color(playerColor).withValues(alpha: 0.8),
              width: scale,
              height: scale,
            )
          : Image.network(
              targetPlayer.commander?.imageUrl ?? '',
              width: scale,
              height: scale,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Color(playerColor).withValues(alpha: 0.8),
                  width: scale,
                  height: scale,
                );
              },
              fit: BoxFit.cover,
            ),
    );
  }
}

class _PartnerImage extends StatelessWidget {
  const _PartnerImage({
    required this.targetPlayer,
    required this.scale,
    required this.playerColor,
  });
  final Player targetPlayer;
  final double scale;
  final int playerColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: targetPlayer.partner?.imageUrl.isEmpty ?? true
          ? Container(
              color: Color(playerColor).withValues(alpha: 0.8),
              width: scale,
              height: scale,
            )
          : Image.network(
              targetPlayer.partner?.imageUrl ?? '',
              width: scale,
              height: scale,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Color(playerColor).withValues(alpha: 0.8),
                  width: scale,
                  height: scale,
                );
              },
              fit: BoxFit.cover,
            ),
    );
  }
}

class _CommanderIcons extends StatelessWidget {
  const _CommanderIcons({
    required this.animationController,
  });
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return animationController.isCompleted
        ? Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.add,
                color: AppColors.white.withValues(alpha: 0.8),
                size: 24,
              ),
              Icon(
                Icons.remove,
                color: AppColors.white.withValues(alpha: 0.8),
                size: 24,
              ),
            ],
          )
        : const SizedBox.shrink();
  }
}
