import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';

/// Central control column containing game controls and utilities.
/// Displays reset button, timer widget, and dice icon.
/// Positioned between the two player columns for easy access.
class CenterControlColumn extends StatelessWidget {
  const CenterControlColumn({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ResetButton(textStyle: textStyle, l10n: l10n),
        const _PauseResumeButton(),
        const TimerWidget(),
        _DiceIcon(onPressed: onPressed),
        _HomeButton(textStyle: textStyle, l10n: l10n),
      ],
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({
    required this.textStyle,
    required this.l10n,
  });
  final TextTheme textStyle;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.refresh,
        color: AppColors.neutral60,
        size: 35,
      ),
      onPressed: () {
        _showConfirmDialog(
          context,
          title: l10n.resetGameDialogText,
          body: '',
          onConfirm: () => context.read<GameBloc>().add(const GameResetEvent()),
        );
      },
    );
  }

  Future<void> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) {
    final textStyle = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          title: Text(
            title,
            style: textStyle.headlineMedium,
          ),
          content: body.isNotEmpty
              ? SizedBox(
                  width: 250,
                  child: Text(
                    body,
                    style: textStyle.titleMedium,
                  ),
                )
              : null,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelTextButton),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
              child: Text(l10n.confirmTextButton),
            ),
          ],
        );
      },
    );
  }
}

class _PauseResumeButton extends StatelessWidget {
  const _PauseResumeButton();

  @override
  Widget build(BuildContext context) {
    final timerBloc = context.watch<TimerBloc>();
    return IconButton(
      onPressed: () => timerBloc.state.status == TimerStatus.paused
          ? timerBloc.add(const TimerResumeEvent())
          : timerBloc.add(const TimerPauseEvent()),
      icon: Icon(
        timerBloc.state.status == TimerStatus.paused
            ? Icons.play_circle_outline_outlined
            : Icons.pause_circle_outline_rounded,
        size: 35,
        color: AppColors.neutral60,
      ),
    );
  }
}

class _DiceIcon extends StatelessWidget {
  const _DiceIcon({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(
        Icons.close_fullscreen,
        color: AppColors.neutral60,
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({
    required this.textStyle,
    required this.l10n,
  });
  final TextTheme textStyle;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        _showConfirmDialog(
          context,
          title: l10n.exitGameDialogText,
          body: l10n.navigationDialogText,
          onConfirm: () {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeRight,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.portraitUp,
            ]);
            GoRouter.of(context).go(HomePage.routeName);
          },
        );
      },
      icon: const Icon(
        Icons.home_filled,
        size: 35,
        color: AppColors.neutral60,
      ),
    );
  }

  Future<void> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) {
    final textStyle = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          title: Text(
            title,
            style: textStyle.headlineMedium,
          ),
          content: body.isNotEmpty
              ? SizedBox(
                  width: 250,
                  child: Text(
                    body,
                    style: textStyle.titleMedium,
                  ),
                )
              : null,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelTextButton),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
              child: Text(l10n.confirmTextButton),
            ),
          ],
        );
      },
    );
  }
}
