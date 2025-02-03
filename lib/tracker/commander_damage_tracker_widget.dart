import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:player_repository/models/models.dart';
import 'package:player_repository/models/opponent.dart';

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

  @override
  Widget build(BuildContext context) {
    final opponent = context.select<PlayerBloc, Opponent>(
      (bloc) => bloc.state.player.opponents.firstWhere(
        (opponent) => opponent.playerId == widget.commanderPlayerId,
      ),
    );

    final damageMap =
        opponent.damages.fold<Map<DamageType, int>>({}, (map, damage) {
      map[damage.damageType] = damage.amount;
      return map;
    });

    final commanderDamage = damageMap[DamageType.commander];
    final partnerDamage = damageMap[DamageType.partner];

    // Debugging statements
    print('CommanderDamageTracker: damageMap = ' + damageMap.toString());
    print('CommanderDamageTracker: commanderDamage = ' +
        (commanderDamage ?? 0).toString());
    print(
        'CommanderDamageTracker: partnerDamage = ' + partnerDamage.toString());

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
                                child: widget.player.commander?.imageUrl
                                            .isEmpty ??
                                        true
                                    ? Container(
                                        color: Color(widget.player.color)
                                            .withValues(alpha: .8),
                                        width: _scaleAnimation.value,
                                        height: _scaleAnimation.value,
                                      )
                                    : Image.network(
                                        widget.player.commander?.imageUrl ?? '',
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
                                child: widget.player.commander?.imageUrl
                                            .isEmpty ??
                                        true
                                    ? Container(
                                        color: Color(widget.player.color)
                                            .withValues(alpha: .8),
                                        width: _scaleAnimation.value,
                                        height: _scaleAnimation.value,
                                      )
                                    : Image.network(
                                        widget.player.partner?.imageUrl ?? '',
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
              child: Container(
                padding: const EdgeInsets.only(top: 5),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: _scaleAnimation.value,
                      height: _scaleAnimation.value,
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        child: widget.player.commander?.imageUrl.isEmpty ?? true
                            ? Container(
                                color: Color(widget.player.color)
                                    .withValues(alpha: .8),
                                width: _scaleAnimation.value,
                                height: _scaleAnimation.value,
                              )
                            : Image.network(
                                widget.player.commander?.imageUrl ?? '',
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
                    ),
                    StrokeText(
                      text: commanderDamage.toString(),
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
