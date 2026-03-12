import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:magic_yeti/tracker/tracker_sizes.dart';
import 'package:player_repository/models/models.dart';

class CommanderDamageTracker extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Selector includes damage amounts to force rebuild when values change.
    final opponent = context.select<PlayerBloc, (Opponent, List<int>)>(
      (bloc) {
        final opp = bloc.state.player.opponents!.firstWhere(
          (o) => o.playerId == commanderPlayerId,
        );
        return (opp, opp.damages.map((d) => d.amount).toList());
      },
    ).$1;

    final targetPlayer = context.select<GameBloc, Player>(
      (bloc) => bloc.state.playerList.firstWhere(
        (p) => p.id == commanderPlayerId,
      ),
    );

    final damageMap = opponent.damages.fold<Map<DamageType, int>>(
      {},
      (map, damage) => map..[damage.damageType] = damage.amount,
    );

    final commanderDamage = damageMap[DamageType.commander] ?? 0;
    final partnerDamage = damageMap[DamageType.partner] ?? 0;
    final hasPartner = targetPlayer.partner?.imageUrl.isNotEmpty ?? false;

    if (!hasPartner) {
      return CommanderDamageButton(
        playerId: playerId,
        commanderPlayerId: commanderPlayerId,
        player: player,
        targetPlayer: targetPlayer,
        commanderDamage: commanderDamage,
        damageType: DamageType.commander,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(
        decoration: BoxDecoration(
          color: Color(targetPlayer.color),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              CommanderDamageButton(
                playerId: playerId,
                commanderPlayerId: commanderPlayerId,
                player: player,
                targetPlayer: targetPlayer,
                commanderDamage: commanderDamage,
                damageType: DamageType.commander,
              ),
              CommanderDamageButton(
                playerId: playerId,
                commanderPlayerId: commanderPlayerId,
                player: player,
                targetPlayer: targetPlayer,
                commanderDamage: partnerDamage,
                damageType: DamageType.partner,
              ),
            ],
          ),
        ),
      ),
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
  Offset? _tapDownPosition;

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
      unawaited(_animationController.reverse());
    }
  }

  void _increment() {
    context.read<PlayerBloc>()
      ..add(
        UpdatePlayerLifeEvent(decrement: true, playerId: widget.playerId),
      )
      ..add(
        PlayerCommanderDamageIncremented(
          commanderId: widget.commanderPlayerId,
          damageType: widget.damageType,
        ),
      );
  }

  void _decrement() {
    context.read<PlayerBloc>()
      ..add(
        UpdatePlayerLifeEvent(decrement: false, playerId: widget.playerId),
      )
      ..add(
        PlayerCommanderDamageDecremented(
          commanderId: widget.commanderPlayerId,
          damageType: widget.damageType,
        ),
      );
  }

  bool _isRightHalf(Offset localPosition) {
    final box = context.findRenderObject()! as RenderBox;
    return localPosition.dx > box.size.width / 2;
  }

  @override
  Widget build(BuildContext context) {
    final sizes = TrackerSizes.fromDevice(
      isPhone: MediaQuery.sizeOf(context).width <= 900,
    );
    final isExpanded = _animationController.isCompleted;
    final size = isExpanded ? sizes.expandedTileSize : sizes.tileSize;

    return TapRegion(
      onTapOutside: (_) => _handleTapOutside(),
      child: GestureDetector(
        onTapDown: (details) => _tapDownPosition = details.localPosition,
        onTap: () {
          if (isExpanded || _tapDownPosition == null) return;
          _isRightHalf(_tapDownPosition!) ? _increment() : _decrement();
        },
        onLongPressStart: (_) {
          if (!isExpanded) unawaited(_animationController.forward());
        },
        onLongPressDown: (details) {
          if (!isExpanded) return;
          _isRightHalf(details.localPosition) ? _increment() : _decrement();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.damageType == DamageType.commander)
                _CommanderImage(
                  targetPlayer: widget.targetPlayer,
                  scale: size,
                  playerColor: widget.player.color,
                )
              else
                _PartnerImage(
                  targetPlayer: widget.targetPlayer,
                  scale: size,
                  playerColor: widget.player.color,
                ),
              _CommanderIcons(animationController: _animationController),
              StrokeText(
                text: widget.commanderDamage.toString(),
                fontSize: sizes.textSize,
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
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: Color(playerColor).withValues(alpha: 0.8),
                width: scale,
                height: scale,
              ),
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
              color: Color(playerColor),
              width: scale,
              height: scale,
            )
          : Image.network(
              targetPlayer.partner?.imageUrl ?? '',
              width: scale,
              height: scale,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: Color(playerColor),
                width: scale,
                height: scale,
              ),
            ),
    );
  }
}

class _CommanderIcons extends StatelessWidget {
  const _CommanderIcons({required this.animationController});

  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    if (!animationController.isCompleted) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          Icons.remove,
          color: AppColors.white.withValues(alpha: 0.8),
          size: 24,
        ),
        Icon(
          Icons.add,
          color: AppColors.white.withValues(alpha: 0.8),
          size: 24,
        ),
      ],
    );
  }
}
