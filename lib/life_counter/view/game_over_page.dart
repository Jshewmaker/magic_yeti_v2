import 'dart:ui';

import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/view/game_page.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:player_repository/player_repository.dart';

// ─── Design tokens ───────────────────────────────────────────────────────────
class _MC {
  static const background = Color(0xFF080B12);
  static const surface = Color(0xFF0F1320);
  static const surfaceRaised = Color(0xFF161B2E);
  static const border = Color(0xFF1E2640);
  static const accent = Color(0xFF4F8EF7);
  static const gold = Color(0xFFFFB020);
  static const silver = Color(0xFFB0B8CC);
  static const bronze = Color(0xFFCD7F3A);
  static const fourth = Color(0xFF3A4260);
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF7A85A3);

  static Color placementColor(int placement) => switch (placement) {
    1 => gold,
    2 => silver,
    3 => bronze,
    _ => fourth,
  };

  static String placementLabel(int placement) => switch (placement) {
    1 => '1ST',
    2 => '2ND',
    3 => '3RD',
    _ => '4TH',
  };
}

// ─── Page ────────────────────────────────────────────────────────────────────
class GameOverPage extends StatelessWidget {
  const GameOverPage({super.key});

  factory GameOverPage.pageBuilder(Object _, Object __) =>
      const GameOverPage(key: Key('game_over_page'));

  static const routeName = 'game_over_page';
  static String get routePath => '/game_over_page';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameOverBloc(
        players: context.read<PlayerRepository>().getPlayers(),
        firebaseDatabaseRepository: context.read<FirebaseDatabaseRepository>(),
      ),
      child: const GameOverView(),
    );
  }
}

// ─── View ────────────────────────────────────────────────────────────────────
class GameOverView extends StatelessWidget {
  const GameOverView({super.key});

  @override
  Widget build(BuildContext context) {
    final gameModel = context.watch<GameBloc>().state.gameModel;
    if (gameModel == null) {
      return const Scaffold(
        backgroundColor: _MC.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canRestoreGame = context.read<PlayerRepository>().canRestoreGame;

    return Scaffold(
      backgroundColor: _MC.background,
      body: BlocBuilder<GameOverBloc, GameOverState>(
        builder: (context, state) {
          final players = state.standings;
          final winner = players.first;

          return Column(
            children: [
              _Header(canRestoreGame: canRestoreGame),
              _WinnerHero(winner: winner),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _StandingsPanel(state: state),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: _DetailsPanel(
                          state: state,
                          players: players,
                          gameModel: gameModel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.canRestoreGame});
  final bool canRestoreGame;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _MC.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: canRestoreGame ? const _RestoreButton() : null,
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                'MATCH COMPLETE',
                style: TextStyle(
                  color: _MC.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.l10n.gameOverTitle,
                style: const TextStyle(
                  color: _MC.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 140),
        ],
      ),
    );
  }
}

class _RestoreButton extends StatelessWidget {
  const _RestoreButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: _MC.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 13),
      label: const Text(
        'RESTORE GAME',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      onPressed: () {
        context.read<TimerBloc>().add(const TimerStartEvent());
        context.read<GameBloc>()
          ..add(const GameRestoreRequested())
          ..add(const GameResumeEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.gameRestoredMessage)),
        );
        context.go(GamePage.routePath);
      },
    );
  }
}

// ─── Winner Hero ─────────────────────────────────────────────────────────────
class _WinnerHero extends StatelessWidget {
  const _WinnerHero({required this.winner});
  final Player winner;

  @override
  Widget build(BuildContext context) {
    final elapsed = context.watch<TimerBloc>().state.elapsedSeconds;
    final l10n = context.l10n;
    final hasArt = winner.commander?.imageUrl.isNotEmpty ?? false;

    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _MC.surfaceRaised,
        border: Border.all(color: _MC.gold.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Commander art
          if (hasArt) ...[
            Image.network(
              winner.commander!.imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            // Gradient scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],

          // Gold left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_MC.gold, Color(0x44FFB020)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Row(
              // crossAxisAlignment defaults to center
              children: [
                // Winner info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: _MC.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            l10n.winner.toUpperCase(),
                            style: const TextStyle(
                              color: _MC.gold,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        winner.name,
                        style: const TextStyle(
                          color: _MC.textPrimary,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (winner.commander?.name.isNotEmpty ?? false) ...[
                        const SizedBox(height: 5),
                        Text(
                          winner.commander!.name,
                          style: const TextStyle(
                            color: _MC.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Duration chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _MC.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.gameDuration.toUpperCase(),
                        style: const TextStyle(
                          color: _MC.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _formatDuration(elapsed),
                        style: const TextStyle(
                          color: _MC.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Standings Panel ─────────────────────────────────────────────────────────
class _StandingsPanel extends StatelessWidget {
  const _StandingsPanel({required this.state});
  final GameOverState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _MC.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _MC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'FINAL STANDINGS',
                style: TextStyle(
                  color: _MC.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              SizedBox(width: 8),
              Tooltip(
                message: 'Drag to reorder',
                waitDuration: Duration(milliseconds: 100),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: _MC.textSecondary,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final scale = lerpDouble(
                    1,
                    1.02,
                    Curves.easeInOut.transform(animation.value),
                  )!;
                  return Transform.scale(
                    scale: scale,
                    child: _StandingRow(
                      key: ValueKey('proxy_$index'),
                      player: state.standings[index],
                      placement: index + 1,
                    ),
                  );
                },
              );
            },
            itemCount: state.standings.length,
            onReorder: (oldIndex, newIndex) {
              context.read<GameOverBloc>().add(
                UpdateStandingsEvent(
                  oldIndex: oldIndex,
                  newIndex: newIndex,
                ),
              );
            },
            itemBuilder: (context, index) {
              final player = state.standings[index];
              return _StandingRow(
                key: ValueKey(player.id),
                player: player,
                placement: index + 1,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.player,
    required this.placement,
    super.key,
  });

  final Player player;
  final int placement;

  @override
  Widget build(BuildContext context) {
    final color = _MC.placementColor(placement);
    final hasArt = player.commander?.imageUrl.isNotEmpty ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 90,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _MC.surfaceRaised,
        border: Border.all(
          color: placement == 1 ? _MC.gold.withValues(alpha: 0.3) : _MC.border,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Commander art as subtle background
          if (hasArt)
            Opacity(
              opacity: 0.2,
              child: Image.network(
                player.commander!.imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

          Row(
            children: [
              // Placement color bar
              Container(width: 4, color: color),
              const SizedBox(width: 14),

              // Placement label
              SizedBox(
                width: 36,
                child: Text(
                  _MC.placementLabel(placement),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // Player + commander name
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        color: _MC.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (player.commander?.name.isNotEmpty ?? false)
                      Text(
                        player.commander!.name,
                        style: const TextStyle(
                          color: _MC.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),

              // Drag handle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: _MC.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Details Panel ───────────────────────────────────────────────────────────
class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.state,
    required this.players,
    required this.gameModel,
  });

  final GameOverState state;
  final List<Player> players;
  final GameModel gameModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canSubmit =
        state.selectedPlayerId != null && state.firstPlayerId != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _MC.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _MC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MATCH DETAILS',
            style: TextStyle(
              color: _MC.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 20),

          // Who went first
          _FieldLabel(label: l10n.whoWentFirst),
          const SizedBox(height: 8),
          _PlayerDropdown(
            value: state.firstPlayerId,
            players: players,
            onChanged: (v) =>
                context.read<GameOverBloc>().add(UpdateFirstPlayerEvent(v)),
          ),
          const SizedBox(height: 20),

          // Account owner
          Row(
            children: [
              Text(
                l10n.accountOwner,
                style: const TextStyle(
                  color: _MC.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
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
                  color: _MC.textSecondary,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PlayerDropdown(
            value: state.selectedPlayerId,
            players: players,
            onChanged: (v) =>
                context.read<GameOverBloc>().add(UpdateSelectedPlayerEvent(v)),
          ),

          const Spacer(),

          // Required-fields hint
          if (!canSubmit) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: _MC.textSecondary,
                  size: 13,
                ),
                const SizedBox(width: 6),
                Text(
                  'Fill out both fields to continue',
                  style: TextStyle(
                    color: _MC.textSecondary.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: l10n.returnToHome,
                  isPrimary: false,
                  enabled: canSubmit,
                  onPressed: () {
                    final userId = context.read<AppBloc>().state.user.id;
                    context.read<GameOverBloc>().add(
                      SendGameOverStatsEvent(
                        gameModel: gameModel,
                        userId: userId,
                      ),
                    );
                    context.go(HomePage.routeName);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: l10n.playAgain,
                  isPrimary: true,
                  enabled: canSubmit,
                  onPressed: () {
                    final userId = context.read<AppBloc>().state.user.id;
                    context.read<GameOverBloc>().add(
                      SendGameOverStatsEvent(
                        gameModel: gameModel,
                        userId: userId,
                      ),
                    );
                    context.read<GameBloc>().add(const GameResetEvent());
                    context.read<TimerBloc>()
                      ..add(const TimerResetEvent())
                      ..add(const TimerStartEvent());
                    context.go(GamePage.routePath);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _MC.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _PlayerDropdown extends StatelessWidget {
  const _PlayerDropdown({
    required this.value,
    required this.players,
    required this.onChanged,
  });

  final String? value;
  final List<Player> players;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: _MC.surfaceRaised,
      style: const TextStyle(
        color: _MC.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      iconEnabledColor: _MC.textSecondary,
      decoration: InputDecoration(
        filled: true,
        fillColor: _MC.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _MC.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _MC.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _MC.accent, width: 1.5),
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
              child: Text(p.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 12,
      letterSpacing: 0.5,
    );

    if (isPrimary) {
      return ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _MC.accent,
          disabledBackgroundColor: _MC.border,
          foregroundColor: Colors.white,
          disabledForegroundColor: _MC.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(label, style: labelStyle),
      );
    }

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? _MC.textPrimary : _MC.textSecondary,
        side: BorderSide(
          color: enabled ? _MC.border : _MC.border.withValues(alpha: 0.4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label, style: labelStyle),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
String _formatDuration(int seconds) {
  final d = Duration(seconds: seconds);
  return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
}
