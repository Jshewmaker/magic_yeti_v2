import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/life_counter_widget.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/tracker/tracker.dart';
import 'package:player_repository/player_repository.dart';

/// One player's area of the game screen: the life counter, plus a drawer of
/// trackers that opens from the edge nearest that player.
///
/// Returns an [Expanded], so place it directly in a [Row] or [Column].
class PlayerTile extends StatelessWidget {
  const PlayerTile({
    required this.playerId,
    required this.rotate,
    required this.leftSideTracker,
    this.borderRadius,
    this.fitLifeToTile = false,
    this.trackerPadding = EdgeInsets.zero,
    super.key,
  });

  final String playerId;

  /// Turns the tile 180 degrees, for the player across the table.
  final bool rotate;
  final bool leftSideTracker;

  /// Overrides the default corner rounding of the life counter.
  final BorderRadius? borderRadius;

  /// Sizes the life total to the tile instead of using a fixed size.
  final bool fitLifeToTile;

  /// Space between the tile edge and the tracker drawer. Use it to keep the
  /// drawer clear of the notch or home indicator when the tile runs to the
  /// screen edge.
  final EdgeInsets trackerPadding;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc(
        playerRepository: context.read<PlayerRepository>(),
        playerId: playerId,
      ),
      child: Expanded(
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: LifeCounterWidget(
                  rotate: rotate,
                  leftSideTracker: leftSideTracker,
                  borderRadius: borderRadius,
                  fitLifeToTile: fitLifeToTile,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: trackerPadding,
                  child: _TrackerOverlay(
                    rotate: rotate,
                    playerId: playerId,
                    leftSideTracker: leftSideTracker,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackerOverlay extends StatefulWidget {
  const _TrackerOverlay({
    required this.rotate,
    required this.playerId,
    required this.leftSideTracker,
  });

  final bool rotate;
  final String playerId;
  final bool leftSideTracker;

  @override
  State<_TrackerOverlay> createState() => _TrackerOverlayState();
}

class _TrackerOverlayState extends State<_TrackerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _sizeAnimation;
  Timer? _autoHideTimer;

  static const _autoHideDuration = Duration(seconds: 5);
  static const _handleHeight = 64.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isDismissed ||
        _controller.status == AnimationStatus.reverse) {
      unawaited(_controller.forward());
      _resetAutoHide();
    } else {
      unawaited(_controller.reverse());
      _autoHideTimer?.cancel();
    }
  }

  void _resetAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(_autoHideDuration, () {
      if (mounted) unawaited(_controller.reverse());
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizes = TrackerSizes.fromDevice(
      isPhone: DeviceInfoProvider.of(context).isPhone,
    );
    final isTopEdge = widget.rotate;

    final trackerContent = Listener(
      onPointerDown: (_) => _resetAutoHide(),
      child: SizedBox(
        height: sizes.panelHeight,
        child: TrackerWidgets(
          rotate: !widget.rotate,
          playerId: widget.playerId,
          leftSideTracker: widget.leftSideTracker,
        ),
      ),
    );

    final handle = GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final isOpen = _controller.value > 0.5;
          final arrowIcon = isTopEdge
              ? (isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down)
              : (isOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up);
          return SizedBox(
            width: double.infinity,
            height: _handleHeight,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(arrowIcon, size: 66, color: Colors.black),
                  Icon(arrowIcon, size: 64, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );

    final panel = SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: isTopEdge ? 1 : -1,
      child: trackerContent,
    );

    return Align(
      alignment: isTopEdge ? Alignment.topCenter : Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: isTopEdge ? [panel, handle] : [handle, panel],
      ),
    );
  }
}
