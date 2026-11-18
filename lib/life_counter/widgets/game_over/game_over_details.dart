import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_actions.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_standings.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_tags.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over_tokens.dart';
import 'package:player_repository/player_repository.dart';

class GameOverDetailsPanel extends StatelessWidget {
  const GameOverDetailsPanel({
    required this.state,
    required this.players,
    required this.gameModel,
    super.key,
  });

  final GameOverState state;
  final List<Player> players;
  final GameModel gameModel;

  @override
  Widget build(BuildContext context) {
    final canSubmit = canSubmitGameOver(state);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameOverTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameOverTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MATCH DETAILS',
            style: TextStyle(
              color: GameOverTokens.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 20),

          // Scrolls so the tags and large text scales fit the fixed-height
          // panel; the action bar below stays pinned.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GameOverDetailsFields(
                    state: state,
                    players: players,
                    currentUserId: context.read<AppBloc>().state.user.id,
                  ),
                  const SizedBox(height: 24),
                  GameOverSectionLabel(
                    label: context.l10n.gameTagsHeading.toUpperCase(),
                  ),
                  const SizedBox(height: 14),
                  GameOverTagsSection(state: state),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          GameOverActionBar(
            canSubmit: canSubmit,
            onReturnHome: () {
              final userId = context.read<AppBloc>().state.user.id;
              context.read<GameOverBloc>().add(
                SendGameOverStatsEvent(gameModel: gameModel, userId: userId),
              );
            },
            onPlayAgain: () {
              final userId = context.read<AppBloc>().state.user.id;
              context.read<GameOverBloc>().add(
                SendGameOverStatsEvent(
                  gameModel: gameModel,
                  userId: userId,
                  exitIntent: GameOverExitIntent.playAgain,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class GameOverDetailsFields extends StatelessWidget {
  const GameOverDetailsFields({
    required this.state,
    required this.players,
    required this.currentUserId,
    this.compact = false,
    super.key,
  });

  final GameOverState state;
  final List<Player> players;
  final String currentUserId;

  /// Uses the short account-owner label. The full sentence wraps to three
  /// lines on a phone, and the adjacent tooltip already carries the detail.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameOverFieldLabel(label: l10n.whoWentFirst),
        const SizedBox(height: 8),
        FirstPlayerDropdown(
          value: state.firstPlayerId,
          players: players,
          onChanged: (v) =>
              context.read<GameOverBloc>().add(UpdateFirstPlayerEvent(v)),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Flexible(
              child: Text(
                compact ? l10n.accountOwnerShort : l10n.accountOwner,
                style: const TextStyle(
                  color: GameOverTokens.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              showDuration: Duration(milliseconds: 3000),
              message:
                  'We use this field to sync the data to the\n'
                  "current logged in user's account.\n"
                  "Don't worry, a game id will be generated so\n"
                  'the other players can add this game to their '
                  'account!',
              child: Icon(
                Icons.info_outline_rounded,
                color: GameOverTokens.textSecondary,
                size: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AccountOwnerDropdown(
          key: const ValueKey('game_over_account_owner_dropdown'),
          value: state.selectedPlayerId,
          players: players,
          currentUserId: currentUserId,
          onChanged: (v) =>
              context.read<GameOverBloc>().add(UpdateSelectedPlayerEvent(v)),
        ),
      ],
    );
  }
}

class GameOverFieldLabel extends StatelessWidget {
  const GameOverFieldLabel({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: GameOverTokens.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class FirstPlayerDropdown extends StatelessWidget {
  const FirstPlayerDropdown({
    required this.value,
    required this.players,
    required this.onChanged,
    super.key,
  });

  final String? value;
  final List<Player> players;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: GameOverTokens.surfaceRaised,
      style: const TextStyle(
        color: GameOverTokens.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      iconEnabledColor: GameOverTokens.textSecondary,
      decoration: InputDecoration(
        filled: true,
        fillColor: GameOverTokens.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GameOverTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GameOverTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: GameOverTokens.accent,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: players
          .map(
            (p) => DropdownMenuItem(
              value: p.id,
              child: Text(
                p.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class AccountOwnerDropdown extends StatelessWidget {
  const AccountOwnerDropdown({
    required this.value,
    required this.players,
    required this.currentUserId,
    required this.onChanged,
    super.key,
  });

  final String? value;
  final List<Player> players;
  final String currentUserId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectable = players
        .where(
          (p) => p.firebaseId == null || p.firebaseId == currentUserId,
        )
        .toList();
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: GameOverTokens.surfaceRaised,
      style: const TextStyle(
        color: GameOverTokens.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      iconEnabledColor: GameOverTokens.textSecondary,
      decoration: InputDecoration(
        filled: true,
        fillColor: GameOverTokens.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GameOverTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GameOverTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: GameOverTokens.accent,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: [
        ...selectable.map(
          (p) => DropdownMenuItem(
            value: p.id,
            child: Text(
              p.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        DropdownMenuItem(
          value: GameOverBloc.notPlayingId,
          child: Text(
            context.l10n.notPlayingOption,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
