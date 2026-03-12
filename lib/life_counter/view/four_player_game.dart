import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/utils/device_info_provider.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/tracker/tracker.dart';
import 'package:player_repository/player_repository.dart';

/// Main view widget for the four-player game layout.
/// Arranges players in a 2x2 grid with central controls.
@visibleForTesting
class FourPlayerGame extends StatefulWidget {
  const FourPlayerGame({super.key});

  @override
  State<FourPlayerGame> createState() => _FourPlayerGameState();
}

class _FourPlayerGameState extends State<FourPlayerGame> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]),
    );
  }

  void _toggleExpanded() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(
        child: Scaffold(
          body: BlocBuilder<GameBloc, GameState>(
            buildWhen: (previous, current) =>
                previous.playerList != current.playerList,
            builder: (context, state) {
              final playerList = state.playerList;
              return Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            PlayerTile(
                              playerId: playerList[2].id,
                              rotate: true,
                              leftSideTracker: true,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            PlayerTile(
                              playerId: playerList[1].id,
                              rotate: false,
                              leftSideTracker: true,
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _isExpanded ? 50 : 2,
                        child: _isExpanded
                            ? CenterControlColumn(onPressed: _toggleExpanded)
                            : null,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            PlayerTile(
                              playerId: playerList[3].id,
                              rotate: true,
                              leftSideTracker: false,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            PlayerTile(
                              playerId: playerList[0].id,
                              rotate: false,
                              leftSideTracker: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!_isExpanded)
                    _CollapsedMenuButton(onTap: _toggleExpanded),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class PlayerTile extends StatelessWidget {
  const PlayerTile({
    required this.playerId,
    required this.rotate,
    required this.leftSideTracker,
    super.key,
  });

  final String playerId;
  final bool rotate;
  final bool leftSideTracker;

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
                ),
              ),
              Positioned.fill(
                child: _TrackerOverlay(
                  rotate: rotate,
                  playerId: playerId,
                  leftSideTracker: leftSideTracker,
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
        children: isTopEdge
            ? [panel, handle]
            : [handle, panel],
      ),
    );
  }
}

class _CollapsedMenuButton extends StatelessWidget {
  const _CollapsedMenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: onTap,
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: ClipOval(
            child: Image.asset(
              'assets/icon/yeti_icon.png',
              color: Colors.white,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
