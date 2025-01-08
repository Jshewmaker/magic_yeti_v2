import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/life_counter/bloc/life_change_bloc.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/view/customize_player_page.dart';
import 'package:player_repository/player_repository.dart';

class LifeCounterWidget extends StatelessWidget {
  LifeCounterWidget({
    this.rotate = false,
    super.key,
  });
  final bool rotate;

  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerBloc>().state.player;
    textController.text = player.name;
    return RotatedBox(
      quarterTurns: rotate ? 2 : 0,
      child: Stack(
        children: [
          BackgroundWidget(player: player),
          _LifeTrackerWidget(lifePoints: player.lifePoints),
          Row(
            children: [
              DecrementLifeWidget(player: player),
              IncrementLifeWidget(player: player),
            ],
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
    );
  }
}

class IncrementLifeWidget extends StatelessWidget {
  const IncrementLifeWidget({
    required this.player,
    super.key,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      key: const ValueKey(
        'life_counter_widget_increment',
      ),
      child: GestureDetector(
        onTap: () => context.read<PlayerBloc>().add(
              UpdatePlayerLifeEvent(decrement: false, playerId: player.id),
            ),
        onLongPressStart: (_) => context.read<PlayerBloc>().add(
              UpdatePlayerLifeByXEvent(decrement: false, playerId: player.id),
            ),
        onLongPressEnd: (_) => context.read<PlayerBloc>().add(
              const PlayerStopDecrement(),
            ),
      ),
    );
  }
}

class DecrementLifeWidget extends StatelessWidget {
  const DecrementLifeWidget({
    required this.player,
    super.key,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      key: const ValueKey(
        'life_counter_widget_decrement',
      ),
      child: GestureDetector(
        onTap: () => context.read<PlayerBloc>().add(
              UpdatePlayerLifeEvent(
                decrement: true,
                playerId: player.id,
              ),
            ),
        onLongPressStart: (_) => context.read<PlayerBloc>().add(
              UpdatePlayerLifeByXEvent(
                decrement: true,
                playerId: player.id,
              ),
            ),
        onLongPressCancel: () => context.read<PlayerBloc>().add(
              const PlayerStopDecrement(),
            ),
        onLongPressEnd: (_) => context.read<PlayerBloc>().add(
              const PlayerStopDecrement(),
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
    return BlocProvider(
      create: (context) => LifeChangeBloc(),
      child: BlocConsumer<PlayerBloc, PlayerState>(
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
            _LifeText(player: state.player),
            const _LifeChangesWidget(),
          ],
        ),
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
    return Center(
      child: StrokeText(
        text: '${player.lifePoints}',
        fontSize: 96,
        color: player.lifePoints <= 0 ? AppColors.black : AppColors.white,
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
          child: Transform.translate(
            offset: Offset(
              change > 0 ? 75 : -75,
              0,
            ),
            child: _LifePointChangeAnimation(change: change),
          ),
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
      duration: const Duration(seconds: 3),
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
    final prefix = widget.change > 0 ? '+' : '';

    return FadeTransition(
      opacity: _opacityAnimation,
      child: Text(
        '$prefix${widget.change}',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.white.withOpacity(0.3),
        ),
      ),
    );
  }
}

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({
    required this.player,
    super.key,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: SizedBox.expand(
        child: Image.network(
          player.picture,
          fit: BoxFit.fill,
          opacity: AlwaysStoppedAnimation(
            player.lifePoints <= 0 ? .2 : 1,
          ),
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: Color(player.color).withOpacity(
                  player.lifePoints <= 0 ? .3 : 1,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(20),
                ),
              ),
            );
          },
        ),
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
                WidgetStateProperty.all(Colors.white.withOpacity(.8)),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          onPressed: onPressed,
          child: Text(name),
        ),
      ],
    );
  }
}
