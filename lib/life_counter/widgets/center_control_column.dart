import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/widgets/widgets.dart';

/// Central control column containing game controls and utilities.
/// Displays reset button, timer widget, and dice icon.
/// Positioned between the two player columns for easy access.
class CenterControlColumn extends StatelessWidget {
  const CenterControlColumn({super.key});

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
        const _DiceIcon(),
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
        size: 40,
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
    final gameBloc = context.watch<GameBloc>();
    return IconButton(
      onPressed: () => gameBloc.state.status == GameStatus.paused
          ? gameBloc.add(const GameResumeEvent())
          : gameBloc.add(const GamePauseEvent()),
      icon: Icon(
        gameBloc.state.status == GameStatus.paused
            ? Icons.play_circle_outline_outlined
            : Icons.pause_circle_outline_rounded,
        size: 40,
        color: AppColors.neutral60,
      ),
    );
  }
}

class _DiceIcon extends StatelessWidget {
  const _DiceIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      FontAwesomeIcons.diceOne,
      size: 30,
      color: AppColors.neutral60,
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
          onConfirm: () => GoRouter.of(context).go(HomePage.routeName),
        );
      },
      icon: const Icon(
        Icons.home_filled,
        size: 40,
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
