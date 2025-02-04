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

class _CommanderDamageTrackerState extends State<CommanderDamageTracker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  static const double _defaultSize = 70;
  static const double _expandedSize = 140;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: _defaultSize,
      end: _expandedSize,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Add listener to rebuild widget when animation value changes
    _animationController.addListener(() {
      setState(() {});
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
    // Watch for changes in the opponent's damage by including the damage amounts in the selector
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

    return widget.player.partner?.imageUrl.isNotEmpty ?? false
        ? Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Color(widget.player.color),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    TapRegion(
                      onTapOutside: (_) => _handleTapOutside(),
                      child: GestureDetector(
                        onTapDown: (details) {
                          if (_animationController.isCompleted) {
                            // When expanded, check if tap is in top or bottom half
                            final box = context.findRenderObject() as RenderBox;
                            final localPosition =
                                box.globalToLocal(details.globalPosition);
                            final isTopHalf =
                                localPosition.dy < box.size.height / 2;

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
                                      damageType: DamageType.commander,
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
                                      damageType: DamageType.commander,
                                    ),
                                  );
                            }
                          } else {
                            // Original behavior when not expanded
                            context.read<PlayerBloc>().add(
                                  UpdatePlayerLifeEvent(
                                    decrement: true,
                                    playerId: widget.playerId,
                                  ),
                                );
                            context.read<PlayerBloc>().add(
                                  PlayerCommanderDamageIncremented(
                                    commanderId: widget.commanderPlayerId,
                                    damageType: DamageType.commander,
                                  ),
                                );
                          }
                        },
                        onLongPress: () {
                          if (!_animationController.isCompleted) {
                            _animationController.forward();
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
                                    damageType: DamageType.commander,
                                  ),
                                );
                          }
                        },
                        onLongPressUp: () => context.read<PlayerBloc>().add(
                              const PlayerStopDecrement(),
                            ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: _scaleAnimation.value,
                              height: _scaleAnimation.value,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                child: targetPlayer
                                            .commander?.imageUrl.isEmpty ??
                                        true
                                    ? Container(
                                        color: Color(widget.player.color)
                                            .withValues(alpha: .8),
                                        width: _scaleAnimation.value,
                                        height: _scaleAnimation.value,
                                      )
                                    : Image.network(
                                        targetPlayer.commander?.imageUrl ?? '',
                                        width: _scaleAnimation.value,
                                        height: _scaleAnimation.value,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Color(widget.player.color)
                                                .withValues(alpha: .8),
                                            width: _scaleAnimation.value,
                                            height: _scaleAnimation.value,
                                          );
                                        },
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            if (_animationController.isCompleted) ...[
                              Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.white.withOpacity(0.8),
                                  size: 24,
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Icon(
                                  Icons.remove,
                                  color: AppColors.white.withOpacity(0.8),
                                  size: 24,
                                ),
                              ),
                            ],
                            StrokeText(
                              text: commanderDamage.toString(),
                              fontSize: 28,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    TapRegion(
                      onTapOutside: (_) => _handleTapOutside(),
                      child: GestureDetector(
                        onTapDown: (details) {
                          if (_animationController.isCompleted) {
                            // When expanded, check if tap is in top or bottom half
                            final box = context.findRenderObject() as RenderBox;
                            final localPosition =
                                box.globalToLocal(details.globalPosition);
                            final isTopHalf =
                                localPosition.dy < box.size.height / 2;

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
                                      damageType: DamageType.partner,
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
                                      damageType: DamageType.partner,
                                    ),
                                  );
                            }
                          } else {
                            // Original behavior when not expanded
                            context.read<PlayerBloc>().add(
                                  UpdatePlayerLifeEvent(
                                    decrement: true,
                                    playerId: widget.playerId,
                                  ),
                                );
                            context.read<PlayerBloc>().add(
                                  PlayerCommanderDamageIncremented(
                                    commanderId: widget.commanderPlayerId,
                                    damageType: DamageType.partner,
                                  ),
                                );
                          }
                        },
                        onLongPress: () {
                          if (!_animationController.isCompleted) {
                            _animationController.forward();
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
                                    damageType: DamageType.partner,
                                  ),
                                );
                          }
                        },
                        onLongPressUp: () => context.read<PlayerBloc>().add(
                              const PlayerStopDecrement(),
                            ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: _scaleAnimation.value,
                              height: _scaleAnimation.value,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                                child: targetPlayer.partner?.imageUrl.isEmpty ??
                                        true
                                    ? Container(
                                        color: Color(widget.player.color)
                                            .withValues(alpha: .8),
                                        width: _scaleAnimation.value,
                                        height: _scaleAnimation.value,
                                      )
                                    : Image.network(
                                        targetPlayer.partner?.imageUrl ?? '',
                                        width: _scaleAnimation.value,
                                        height: _scaleAnimation.value,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Color(widget.player.color)
                                                .withValues(alpha: .8),
                                            width: _scaleAnimation.value,
                                            height: _scaleAnimation.value,
                                          );
                                        },
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            if (_animationController.isCompleted) ...[
                              Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.white.withOpacity(0.8),
                                  size: 24,
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  color: AppColors.white.withOpacity(0.8),
                                  size: 24,
                                ),
                              ),
                            ],
                            StrokeText(
                              text: partnerDamage.toString(),
                              fontSize: 28,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : TapRegion(
            onTapOutside: (_) => _handleTapOutside(),
            child: GestureDetector(
              onTapDown: (details) {
                if (_animationController.isCompleted) {
                  // When expanded, check if tap is in top or bottom half
                  final box = context.findRenderObject() as RenderBox;
                  final localPosition =
                      box.globalToLocal(details.globalPosition);
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
                            damageType: DamageType.commander,
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
                            damageType: DamageType.commander,
                          ),
                        );
                  }
                } else {
                  // Original behavior when not expanded
                  context.read<PlayerBloc>().add(
                        UpdatePlayerLifeEvent(
                          decrement: true,
                          playerId: widget.playerId,
                        ),
                      );
                  context.read<PlayerBloc>().add(
                        PlayerCommanderDamageIncremented(
                          commanderId: widget.commanderPlayerId,
                          damageType: DamageType.commander,
                        ),
                      );
                }
              },
              onLongPress: () {
                if (!_animationController.isCompleted) {
                  _animationController.forward();
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
                          damageType: DamageType.commander,
                        ),
                      );
                }
              },
              onLongPressUp: () => context.read<PlayerBloc>().add(
                    const PlayerStopDecrement(),
                  ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: _scaleAnimation.value,
                    height: _scaleAnimation.value,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          child: targetPlayer.commander?.imageUrl.isEmpty ??
                                  true
                              ? Container(
                                  color: Color(widget.player.color)
                                      .withValues(alpha: .8),
                                  width: _scaleAnimation.value,
                                  height: _scaleAnimation.value,
                                )
                              : Image.network(
                                  targetPlayer.commander?.imageUrl ?? '',
                                  width: _scaleAnimation.value,
                                  height: _scaleAnimation.value,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Color(widget.player.color)
                                          .withValues(alpha: .8),
                                      width: _scaleAnimation.value,
                                      height: _scaleAnimation.value,
                                    );
                                  },
                                  fit: BoxFit.cover,
                                ),
                        ),
                        if (_animationController.isCompleted) ...[
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Icon(
                              Icons.add,
                              color: AppColors.white.withValues(alpha: 0.8),
                              size: 24,
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Icon(
                              Icons.remove,
                              color: AppColors.white.withValues(alpha: 0.8),
                              size: 24,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  StrokeText(
                    text: commanderDamage.toString(),
                    fontSize: 28,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          );
  }
}
