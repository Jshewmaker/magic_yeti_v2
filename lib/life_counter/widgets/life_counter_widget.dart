import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magic_yeti/app/utils/device_info_provider.dart';
import 'package:magic_yeti/life_counter/bloc/life_change_bloc.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/view/customize_player_page.dart';
import 'package:magic_yeti/timer/widgets/auto_resume_timer_wrapper.dart';
import 'package:player_repository/player_repository.dart';

class LifeCounterWidget extends StatelessWidget {
  LifeCounterWidget({
    required this.leftSideTracker,
    this.rotate = false,
    super.key,
  });
  final bool rotate;
  final bool leftSideTracker;

  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerBloc>().state.player;
    textController.text = player.name;
    return BlocProvider(
      create: (context) => LifeChangeBloc(),
      child: ClipRRect(
        borderRadius: leftSideTracker
            ? const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
        child: RotatedBox(
          quarterTurns: rotate ? 2 : 0,
          child: Stack(
            children: [
              BackgroundWidget(
                player: player,
                rotate: rotate,
                leftSideTracker: true,
              ),
              _LifeTrackerWidget(lifePoints: player.lifePoints),
              AutoResumeTimerWrapper(
                child: Row(
                  children: [
                    DecrementLifeWidget(player: player),
                    IncrementLifeWidget(player: player),
                  ],
                ),
              ),
              _PlayerNameWidget(
                name: textController.text,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PlayerBloc>(),
                        child: CustomizePlayerPage(
                          playerId: player.id,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IncrementLifeWidget extends StatefulWidget {
  const IncrementLifeWidget({
    required this.player,
    super.key,
  });

  final Player player;

  @override
  State<IncrementLifeWidget> createState() => _IncrementLifeWidgetState();
}

class _IncrementLifeWidgetState extends State<IncrementLifeWidget> {
  bool _isTapped = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isTapped = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isTapped = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lifeChange = context.read<LifeChangeBloc>().state.change;
    final isPhone = DeviceInfoProvider.of(context).isPhone;
    return Expanded(
      key: const ValueKey(
        'life_counter_widget_increment',
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTap: () => context.read<PlayerBloc>().add(
              UpdatePlayerLifeEvent(
                decrement: false,
                playerId: widget.player.id,
              ),
            ),
        onLongPressStart: (_) => context.read<PlayerBloc>().add(
              UpdatePlayerLifeByXEvent(
                decrement: false,
                playerId: widget.player.id,
              ),
            ),
        onLongPressEnd: (_) => context.read<PlayerBloc>().add(
              const PlayerStopDecrement(),
            ),
        child: AnimatedContainer(
          decoration: BoxDecoration(
            color: _isTapped ? Colors.white.withAlpha(32) : Colors.transparent,
            borderRadius: const BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          duration: const Duration(milliseconds: 50),
          child: SizedBox.expand(
            child: Padding(
              padding:
                  isPhone ? const EdgeInsets.all(8) : const EdgeInsets.all(64),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (lifeChange != null && lifeChange > 0)
                    const _LifeChangesWidget(),
                  const SizedBox(width: 8),
                  const FaIcon(FontAwesomeIcons.plus, size: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DecrementLifeWidget extends StatefulWidget {
  const DecrementLifeWidget({
    required this.player,
    super.key,
  });

  final Player player;

  @override
  State<DecrementLifeWidget> createState() => _DecrementLifeWidgetState();
}

class _DecrementLifeWidgetState extends State<DecrementLifeWidget> {
  bool _isTapped = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isTapped = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isTapped = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lifeChange = context.read<LifeChangeBloc>().state.change;
    final isPhone = DeviceInfoProvider.of(context).isPhone;
    return Expanded(
      key: const ValueKey(
        'life_counter_widget_decrement',
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTap: () => context.read<PlayerBloc>().add(
              UpdatePlayerLifeEvent(
                decrement: true,
                playerId: widget.player.id,
              ),
            ),
        onLongPressStart: (_) => context.read<PlayerBloc>().add(
              UpdatePlayerLifeByXEvent(
                decrement: true,
                playerId: widget.player.id,
              ),
            ),
        onLongPressCancel: () => context.read<PlayerBloc>().add(
              const PlayerStopDecrement(),
            ),
        onLongPressEnd: (_) => context.read<PlayerBloc>().add(
              const PlayerStopDecrement(),
            ),
        child: Padding(
          padding: isPhone ? const EdgeInsets.all(8) : const EdgeInsets.all(64),
          child: AnimatedContainer(
            decoration: BoxDecoration(
              color:
                  _isTapped ? Colors.white.withAlpha(32) : Colors.transparent,
              borderRadius: const BorderRadius.all(
                Radius.circular(20),
              ),
            ),
            duration: const Duration(milliseconds: 50),
            child: SizedBox.expand(
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.minus, size: 36),
                  const SizedBox(width: 8),
                  if (lifeChange != null && lifeChange < 0)
                    const _LifeChangesWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LifeTrackerWidget extends StatelessWidget {
  const _LifeTrackerWidget({
    required this.lifePoints,
  });

  final int lifePoints;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayerBloc, PlayerState>(
      listener: (context, state) {
        if (state.status == PlayerStatus.lifeTotalUpdated) {
          context.read<LifeChangeBloc>().add(
                LifePointsChanged(
                  previousLifePoints: lifePoints,
                  newLifePoints: state.player.lifePoints,
                ),
              );
        }
      },
      builder: (context, state) => Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          if (state.player.state.isEliminated)
            const Center(
              child: FaIcon(
                FontAwesomeIcons.skullCrossbones,
                size: 96,
                color: AppColors.black,
              ),
            )
          else
            _LifeText(player: state.player),
        ],
      ),
    );
  }
}

class _LifeText extends StatelessWidget {
  const _LifeText({
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceInfoProvider.of(context).isPhone;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: StrokeText(
          text: '${player.lifePoints}',
          fontSize: isPhone ? 48 : 180,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _LifeChangesWidget extends StatelessWidget {
  const _LifeChangesWidget();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LifeChangeBloc, LifeChangeState>(
      builder: (context, state) {
        final change = state.change;
        if (change == null || change == 0) return const SizedBox();

        return Center(
          child: _LifePointChangeAnimation(change: change),
        );
      },
    );
  }
}

class _LifePointChangeAnimation extends StatefulWidget {
  const _LifePointChangeAnimation({
    required this.change,
  });

  final int change;

  @override
  State<_LifePointChangeAnimation> createState() =>
      _LifePointChangeAnimationState();
}

class _LifePointChangeAnimationState extends State<_LifePointChangeAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  int _lastChange = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  @override
  void didUpdateWidget(_LifePointChangeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.change != _lastChange) {
      // Reset the animation if the value changes
      _controller.dispose();
      _initializeAnimation();
    }
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1),
      ),
    );

    _lastChange = widget.change;
    _controller
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          context.read<LifeChangeBloc>().add(
                const LifePointChangeCompleted(),
              );
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: StrokeText(
        text: '${widget.change.abs()}',
        fontSize: 64,
        color: AppColors.white,
      ),
    );
  }
}

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({
    required this.player,
    required this.rotate,
    required this.leftSideTracker,
    super.key,
  });

  final Player player;
  final bool rotate;
  final bool leftSideTracker;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: player.partner?.imageUrl == null
          ? Image.network(
              player.commander?.imageUrl ?? '',
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(
                player.state.isEliminated ? 0.2 : 1,
              ),
              errorBuilder: (context, error, stackTrace) {
                return Opacity(
                  opacity: player.state.isEliminated ? 0.2 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        tileMode: TileMode.mirror,
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(player.color).withValues(alpha: 1.8),
                          Color(player.color),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.network(
                    player.commander?.imageUrl ?? '',
                    fit: BoxFit.fitHeight,
                    opacity: AlwaysStoppedAnimation(
                      player.state.isEliminated ? 0.2 : 1,
                    ),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(player.color).withValues(
                                alpha: player.state.isEliminated ? 0.3 : 1.0,
                              ),
                              Color(player.color).withValues(
                                alpha: player.state.isEliminated ? 0.3 : 0.7,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Image.network(
                    player.partner?.imageUrl ?? '',
                    fit: BoxFit.fitHeight,
                    opacity: AlwaysStoppedAnimation(
                      player.state.isEliminated ? 0.2 : 1,
                    ),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(player.color).withValues(
                                alpha: player.state.isEliminated ? 0.3 : 1.0,
                              ),
                              Color(player.color).withValues(
                                alpha: player.state.isEliminated ? 0.3 : 0.7,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _PlayerNameWidget extends StatelessWidget {
  const _PlayerNameWidget({required this.onPressed, required this.name});
  final void Function()? onPressed;
  final String name;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor:
                WidgetStateProperty.all(Colors.black.withAlpha(150)),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          onPressed: onPressed,
          child: Text(name, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
