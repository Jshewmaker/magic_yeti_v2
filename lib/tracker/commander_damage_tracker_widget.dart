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
    final hasPartner = targetPlayer.partner != null;

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommanderDamageButton(
                playerId: playerId,
                commanderPlayerId: commanderPlayerId,
                player: player,
                targetPlayer: targetPlayer,
                commanderDamage: commanderDamage,
                damageType: DamageType.commander,
              ),
              const SizedBox(width: 4),
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

class _CommanderDamageButtonState extends State<CommanderDamageButton> {
  late final PlayerBloc _playerBloc;
  bool _isHeld = false;

  @override
  void initState() {
    super.initState();
    _playerBloc = context.read<PlayerBloc>();
  }

  @override
  void dispose() {
    // A tile can leave the tree under the finger, and then no lift arrives.
    _endHold();
    super.dispose();
  }

  void _increment() {
    _playerBloc
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

  void _startHold() {
    _isHeld = true;
    _playerBloc.add(
      PlayerCommanderDamageHoldStarted(
        commanderId: widget.commanderPlayerId,
        damageType: widget.damageType,
      ),
    );
  }

  void _endHold() {
    if (!_isHeld) return;
    _isHeld = false;
    _playerBloc.add(const PlayerCommanderDamageHoldEnded());
  }

  @override
  Widget build(BuildContext context) {
    final sizes = TrackerSizes.fromDevice(
      isPhone: DeviceInfoProvider.of(context).isPhone,
    );
    final size = sizes.tileSize;

    // Tap adds one. Hold subtracts one, and keeps subtracting until the finger
    // lifts.
    return GestureDetector(
      onTap: _increment,
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _endHold(),
      onLongPressCancel: _endHold,
      child: SizedBox(
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
            StrokeText(
              text: widget.commanderDamage.toString(),
              fontSize: sizes.textSize,
              color: AppColors.white,
            ),
          ],
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
