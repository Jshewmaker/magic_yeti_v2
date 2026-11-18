# Friend Head-to-Head Stats Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a date-range filter that drives the whole friend head-to-head page, tighten the stat grid, and make each tile self-descriptive with a caption line.

**Architecture:** `FriendStatsBloc` retains the compiled inputs as fields and re-filters/recomputes synchronously on a new `FriendStatsRangeChanged` event (no generation fence needed — compute is synchronous). The page gains a right-aligned `StatsTimeRange` dropdown (reused from home stats) and an "empty in this range" body. A new local `FriendStatCard` (title + value + caption) replaces the shared `StatsWidget` inside the friend grid; the shared widget is untouched.

**Tech Stack:** Flutter, `bloc`/`flutter_bloc`, `equatable`, `bloc_test`, `auto_size_text`, `app_ui`.

## Global Constraints

- Reuse `StatsTimeRange` from `lib/stats_overview/stats_overview_bloc/stats_overview_bloc.dart` (exported by `package:magic_yeti/stats_overview/stats_overview.dart`) — do NOT define a second enum.
- Filter games by `game.endTime.isAfter(cutoff)`; cutoff arithmetic must match `StatsOverviewBloc._filterGames` exactly.
- Do NOT modify `FriendHeadToHeadCalculator`, the `FriendHeadToHead` model, or the shared `StatsWidget`.
- Lint: `very_good_analysis` (strict). Run `flutter analyze` before each commit.
- Tests run from repo root with `flutter test <path>`.

---

## File Structure

- `lib/friends_list/friend_stats/friend_stats_bloc.dart` — add range field, `_filterGames`, `_emitCompiled`, new event handler.
- `lib/friends_list/friend_stats/friend_stats_event.dart` — add `FriendStatsRangeChanged`.
- `lib/friends_list/friend_stats/friend_stats_state.dart` — add `range` to `FriendStatsLoaded`.
- `lib/friends_list/friend_stats/view/friend_stats_tiles.dart` — add `FriendStatCard`; captions in `buildFriendStatTiles`.
- `lib/friends_list/friend_stats/view/friend_stats_page.dart` — dropdown, empty-in-range body, grid tuning.
- Tests: `test/friends_list/friend_stats/friend_stats_bloc_test.dart`, `friend_stats_tiles_test.dart`, `friend_stats_page_test.dart`.

---

## Task 1: Bloc range filter

**Files:**
- Modify: `lib/friends_list/friend_stats/friend_stats_event.dart`
- Modify: `lib/friends_list/friend_stats/friend_stats_state.dart`
- Modify: `lib/friends_list/friend_stats/friend_stats_bloc.dart`
- Test: `test/friends_list/friend_stats/friend_stats_bloc_test.dart`

**Interfaces:**
- Consumes: `StatsTimeRange` (enum with `.allTime`, `.last12Months`, `.last6Months`, `.last3Months`, `.last30Days`) from `package:magic_yeti/stats_overview/stats_overview.dart`.
- Produces:
  - `FriendStatsRangeChanged(StatsTimeRange range)` event.
  - `FriendStatsLoaded(FriendHeadToHead stats, {StatsTimeRange range})` — `range` defaults to `StatsTimeRange.allTime`.

- [ ] **Step 1: Write the failing bloc tests**

Replace the entire body of `test/friends_list/friend_stats/friend_stats_bloc_test.dart` with:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_stats.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:player_repository/player_repository.dart';

Player _seat(String id, String firebaseId, int tod) => Player(
  id: id,
  name: 'Name-$id',
  playerNumber: 0,
  lifePoints: 40,
  color: 0xFF000000,
  opponents: const [],
  placement: 1,
  timeOfDeath: tod,
  firebaseId: firebaseId,
);

/// A shared pod (me + friend) ending at [end]. `me` wins.
GameModel _sharedGameAt(DateTime end) {
  final start = end.subtract(const Duration(hours: 2));
  return GameModel(
    id: 'g-${end.millisecondsSinceEpoch}',
    winnerId: 'me-seat',
    startTime: start,
    endTime: end,
    durationInSeconds: 7200,
    players: [
      _seat('me-seat', 'me', end.millisecondsSinceEpoch),
      _seat('friend-seat', 'friend', start.millisecondsSinceEpoch + 1000),
    ],
  );
}

void main() {
  group('FriendStatsBloc', () {
    blocTest<FriendStatsBloc, FriendStatsState>(
      'emits loading then loaded with computed stats, range all-time',
      build: FriendStatsBloc.new,
      act: (bloc) => bloc.add(
        CompileFriendStats(
          myId: 'me',
          friendId: 'friend',
          games: [_sharedGameAt(DateTime(2026, 1, 1, 14))],
        ),
      ),
      expect: () => [
        isA<FriendStatsLoading>(),
        isA<FriendStatsLoaded>()
            .having((s) => s.stats.sharedPods, 'sharedPods', 1)
            .having((s) => s.range, 'range', StatsTimeRange.allTime),
      ],
    );

    blocTest<FriendStatsBloc, FriendStatsState>(
      'loaded stats reflect an empty shared history',
      build: FriendStatsBloc.new,
      act: (bloc) => bloc.add(
        const CompileFriendStats(myId: 'me', friendId: 'friend', games: []),
      ),
      expect: () => [
        isA<FriendStatsLoading>(),
        isA<FriendStatsLoaded>().having(
          (s) => s.stats.sharedPods,
          'sharedPods',
          0,
        ),
      ],
    );

    blocTest<FriendStatsBloc, FriendStatsState>(
      'range change filters games by endTime and recomputes',
      build: FriendStatsBloc.new,
      act: (bloc) {
        final now = DateTime.now();
        bloc
          ..add(
            CompileFriendStats(
              myId: 'me',
              friendId: 'friend',
              games: [
                _sharedGameAt(now.subtract(const Duration(days: 5))),
                _sharedGameAt(now.subtract(const Duration(days: 400))),
              ],
            ),
          )
          ..add(const FriendStatsRangeChanged(StatsTimeRange.last30Days));
      },
      // Skip the loading+loaded pair emitted by the initial compile.
      skip: 2,
      expect: () => [
        isA<FriendStatsLoading>(),
        isA<FriendStatsLoaded>()
            .having((s) => s.stats.sharedPods, 'sharedPods', 1)
            .having((s) => s.range, 'range', StatsTimeRange.last30Days),
      ],
    );
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/friends_list/friend_stats/friend_stats_bloc_test.dart`
Expected: FAIL — `FriendStatsRangeChanged` undefined and `FriendStatsLoaded` has no `range`.

- [ ] **Step 3: Add the `FriendStatsRangeChanged` event**

In `lib/friends_list/friend_stats/friend_stats_event.dart`, append after the `CompileFriendStats` class (still inside the file, it is `part of 'friend_stats_bloc.dart'`):

```dart
/// Change the time window the head-to-head stats are computed over. Reuses the
/// retained games/ids from the last [CompileFriendStats].
final class FriendStatsRangeChanged extends FriendStatsEvent {
  const FriendStatsRangeChanged(this.range);

  final StatsTimeRange range;

  @override
  List<Object?> get props => [range];
}
```

- [ ] **Step 4: Add `range` to `FriendStatsLoaded`**

In `lib/friends_list/friend_stats/friend_stats_state.dart`, replace the `FriendStatsLoaded` class with:

```dart
final class FriendStatsLoaded extends FriendStatsState {
  const FriendStatsLoaded(this.stats, {this.range = StatsTimeRange.allTime});

  final FriendHeadToHead stats;
  final StatsTimeRange range;

  @override
  List<Object?> get props => [stats, range];
}
```

- [ ] **Step 5: Wire the range filter into the bloc**

Replace the whole body of `lib/friends_list/friend_stats/friend_stats_bloc.dart` with:

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head_calculator.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';

part 'friend_stats_event.dart';
part 'friend_stats_state.dart';

/// Computes head-to-head stats between the signed-in user and one friend from
/// the user's own match history, over a selectable [StatsTimeRange].
///
/// Games are injected via [CompileFriendStats] (from the app-wide match-history
/// stream) and retained as fields so [FriendStatsRangeChanged] can re-filter and
/// recompute without re-fetching. Computation is synchronous and cheap, so no
/// generation fence is needed — events cannot interleave across an await here.
class FriendStatsBloc extends Bloc<FriendStatsEvent, FriendStatsState> {
  FriendStatsBloc() : super(FriendStatsInitial()) {
    on<CompileFriendStats>(_onCompile);
    on<FriendStatsRangeChanged>(_onRangeChanged);
  }

  List<GameModel> _allGames = const [];
  String _myId = '';
  String _friendId = '';
  StatsTimeRange _range = StatsTimeRange.allTime;

  void _onCompile(CompileFriendStats event, Emitter<FriendStatsState> emit) {
    _allGames = event.games;
    _myId = event.myId;
    _friendId = event.friendId;
    _emitCompiled(emit);
  }

  void _onRangeChanged(
    FriendStatsRangeChanged event,
    Emitter<FriendStatsState> emit,
  ) {
    _range = event.range;
    _emitCompiled(emit);
  }

  void _emitCompiled(Emitter<FriendStatsState> emit) {
    emit(FriendStatsLoading());
    try {
      final games = _filterGames(_allGames, _range);
      final stats = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _myId,
        friendId: _friendId,
      );
      emit(FriendStatsLoaded(stats, range: _range));
    } on Object catch (error) {
      emit(FriendStatsFailure(error.toString()));
    }
  }

  /// Keeps games whose `endTime` is after the cutoff for [range]. Mirrors
  /// `StatsOverviewBloc._filterGames` so the two pages agree on boundaries.
  List<GameModel> _filterGames(List<GameModel> games, StatsTimeRange range) {
    if (range == StatsTimeRange.allTime) {
      return games;
    }
    final now = DateTime.now();
    final cutoff = switch (range) {
      StatsTimeRange.last12Months => DateTime(now.year - 1, now.month, now.day),
      StatsTimeRange.last6Months => DateTime(now.year, now.month - 6, now.day),
      StatsTimeRange.last3Months => DateTime(now.year, now.month - 3, now.day),
      StatsTimeRange.last30Days => now.subtract(const Duration(days: 30)),
      StatsTimeRange.allTime => now,
    };
    return games.where((game) => game.endTime.isAfter(cutoff)).toList();
  }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/friends_list/friend_stats/friend_stats_bloc_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Analyze**

Run: `flutter analyze lib/friends_list/friend_stats`
Expected: No issues.

- [ ] **Step 8: Commit**

```bash
git add lib/friends_list/friend_stats/friend_stats_bloc.dart \
        lib/friends_list/friend_stats/friend_stats_event.dart \
        lib/friends_list/friend_stats/friend_stats_state.dart \
        test/friends_list/friend_stats/friend_stats_bloc_test.dart
git commit -m "feat: filter friend head-to-head stats by time range"
```

---

## Task 2: Self-descriptive `FriendStatCard`

**Files:**
- Modify: `lib/friends_list/friend_stats/view/friend_stats_tiles.dart`
- Test: `test/friends_list/friend_stats/friend_stats_tiles_test.dart`

**Interfaces:**
- Produces: `FriendStatCard({required String title, required String stat, required String caption, String? tooltip})` — a `Card` rendering title (+ optional info button) / value / caption.
- `buildFriendStatTiles(FriendHeadToHead stats)` continues to return `List<Widget>`, now `FriendStatCard`s, with the "Time Alive" title renamed to "Avg Time Alive".

- [ ] **Step 1: Update the failing tile tests**

In `test/friends_list/friend_stats/friend_stats_tiles_test.dart`, make these edits:

Change the "gates Time Alive" test's expectation from `'Time Alive'` to `'Avg Time Alive'`:

```dart
    testWidgets('gates Time Alive below five pods', (tester) async {
      final tiles = buildFriendStatTiles(
        _stats(sharedPods: 3, yourAvgSurvival: 0.7, theirAvgSurvival: 0.5),
      );
      await _pump(tester, Column(children: tiles));

      // Time Alive tile present but showing the need-more sentinel.
      expect(find.text('Avg Time Alive'), findsOneWidget);
      expect(find.text('Need 5+'), findsWidgets);
    });
```

Add a new test inside the `buildFriendStatTiles` group verifying captions render:

```dart
    testWidgets('renders captions under the values', (tester) async {
      final tiles = buildFriendStatTiles(
        _stats(sharedPods: 5, youWon: 3, theyWon: 1, fieldWon: 1),
      );
      await _pump(tester, Column(children: tiles));

      expect(find.text('You · Them · Field'), findsOneWidget);
      expect(find.text('3·1·1'), findsOneWidget);
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/friends_list/friend_stats/friend_stats_tiles_test.dart`
Expected: FAIL — `'Avg Time Alive'` and `'You · Them · Field'` not found (still "Time Alive", no captions).

- [ ] **Step 3: Add `FriendStatCard` and use it in `buildFriendStatTiles`**

Replace the whole body of `lib/friends_list/friend_stats/view/friend_stats_tiles.dart` with:

```dart
import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head.dart';

/// The hero tile: a pairwise finish record. This is the one stat with both a
/// real sample and a real story at ~10 pods — "who finishes ahead" is defined
/// in every shared pod with a true 50% baseline, unlike a 25%-event win rate.
class LedgerHeroTile extends StatelessWidget {
  const LedgerHeroTile({
    required this.stats,
    required this.friendName,
    super.key,
  });

  final FriendHeadToHead stats;
  final String friendName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enough = stats.hasEnoughForLedger;

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              'The Ledger',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            if (enough) ...[
              Text(
                '${stats.youFinishedAhead}–${stats.theyFinishedAhead}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'you finish ahead in ${stats.youFinishedAhead} '
                'of ${stats.sharedPods} pods',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral60,
                ),
                textAlign: TextAlign.center,
              ),
            ] else
              Text(
                'Need 3+ pods together',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral60,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single secondary head-to-head stat as a card: a clear title (with an
/// optional info button for the full explanation), the value, and a caption
/// that names what the value means so the info button is rarely needed.
class FriendStatCard extends StatelessWidget {
  const FriendStatCard({
    required this.title,
    required this.stat,
    required this.caption,
    this.tooltip,
    super.key,
  });

  final String title;
  final String stat;
  final String caption;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: AutoSizeText(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                if (tooltip != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: GestureDetector(
                      onTap: () => _showTooltip(context),
                      child: Icon(
                        Icons.info_outline,
                        size: 10,
                        color: Colors.blueGrey.withAlpha(150),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: AutoSizeText(
                  stat,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AutoSizeText(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.neutral60,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          content: Text(tooltip!),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the secondary stat tiles for the grid, applying each stat's sample
/// gate. Damage tiles (The Beatdown, 21s) are omitted entirely below their
/// gates rather than shown as a rivalry of zeroes.
List<Widget> buildFriendStatTiles(FriendHeadToHead stats) {
  int pct(double? f) => ((f ?? 0) * 100).round();

  return [
    FriendStatCard(
      title: 'Pods Won',
      stat: stats.hasEnoughForLedger
          ? '${stats.youWon}·${stats.theyWon}·${stats.fieldWon}'
          : 'Need 3+',
      caption: 'You · Them · Field',
      tooltip:
          'You · Them · Rest of the table, across ${stats.sharedPods} '
          'pods. An even split would be about '
          '${stats.expectedWinsEach.toStringAsFixed(1)} each — in a 4-player '
          'pod the baseline is 25%, not 50%.',
    ),
    FriendStatCard(
      title: 'Their Go-To',
      stat: stats.hasEnoughForTopCommander
          ? (stats.theirTopCommanderName ?? 'Need 3+')
          : 'Need 3+',
      caption: 'Most-played cmdr',
      tooltip: stats.hasEnoughForTopCommander
          ? 'The commander they bring to your table most often '
                '(${stats.theirTopCommanderCount} of ${stats.sharedPods} pods).'
          : 'Their most-played commander at your table (needs 3+ pods).',
    ),
    FriendStatCard(
      title: 'Avg Time Alive',
      stat: stats.hasEnoughForSurvival
          ? '${pct(stats.yourAvgSurvival)}% / ${pct(stats.theirAvgSurvival)}%'
          : 'Need 5+',
      caption: 'You / Them survived',
      tooltip:
          'Average share of the pod each of you survives — you / them. '
          'The Ledger says who outlasts whom; this says by how much.',
    ),
    FriendStatCard(
      title: 'Final Two',
      stat: stats.hasEnoughForFinalTwo
          ? '${stats.finalTwoCount} of ${stats.sharedPods}'
          : 'Need 5+',
      caption: 'Last two standing',
      tooltip:
          'Pods where the two of you were the last players standing — '
          'the mark of a real rivalry.',
    ),
    if (stats.hasBeatdown)
      FriendStatCard(
        title: 'The Beatdown',
        stat: '${stats.commanderDamageDealt} / ${stats.commanderDamageTaken}',
        caption: 'Cmdr dmg dealt / taken',
        tooltip:
            'Total commander damage you have dealt to them / taken from '
            'them across your shared pods.',
      ),
    if (stats.hasLethalBlows)
      FriendStatCard(
        title: '21s',
        stat: '${stats.lethalBlowsLanded} / ${stats.lethalBlowsTaken}',
        caption: 'Lethal 21s: you / them',
        tooltip:
            'Pods where a single commander landed the lethal 21 — you on '
            'them / them on you.',
      ),
  ];
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/friends_list/friend_stats/friend_stats_tiles_test.dart`
Expected: PASS (all tests, including the new caption test).

- [ ] **Step 5: Analyze**

Run: `flutter analyze lib/friends_list/friend_stats`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/friends_list/friend_stats/view/friend_stats_tiles.dart \
        test/friends_list/friend_stats/friend_stats_tiles_test.dart
git commit -m "feat: descriptive caption cards for friend head-to-head tiles"
```

---

## Task 3: Page dropdown, empty-in-range body, tighter grid

**Files:**
- Modify: `lib/friends_list/friend_stats/view/friend_stats_page.dart`
- Test: `test/friends_list/friend_stats/friend_stats_page_test.dart`

**Interfaces:**
- Consumes: `FriendStatsLoaded.range` (Task 1), `FriendStatsRangeChanged` (Task 1), `FriendStatCard` (Task 2), `StatsTimeRange` (from `package:magic_yeti/stats_overview/stats_overview.dart`).
- Produces: no new exports.

- [ ] **Step 1: Update the failing page tests**

In `test/friends_list/friend_stats/friend_stats_page_test.dart`:

Add these imports at the top with the others:

```dart
import 'package:magic_yeti/stats_overview/stats_overview.dart';
```

In the "renders head-to-head stats for the shared pods" test, change the `'Time Alive'` expectation to `'Avg Time Alive'`:

```dart
    expect(find.text('Pods Won'), findsOneWidget);
    expect(find.text('Avg Time Alive'), findsOneWidget);
    expect(find.text('Their Go-To'), findsOneWidget);
```

Add a new test after the existing "shows the empty state when no pods are shared" test. It plays real (past-dated) pods, switches the range to Last 30 Days, and expects the in-range-empty body with the dropdown still present:

```dart
  testWidgets('shows an in-range empty body when the range hides all pods', (
    tester,
  ) async {
    // Pods dated Jan 2026 — outside a Last-30-Days window as of the run date.
    stubHistory([
      _pod('1', meAhead: true),
      _pod('2', meAhead: true),
      _pod('3', meAhead: true),
    ]);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Open the range dropdown and pick Last 30 Days.
    await tester.tap(find.byType(DropdownButton<StatsTimeRange>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 30 Days').last);
    await tester.pumpAndSettle();

    // In-range empty message shows, and the dropdown is still available to
    // widen the range back out.
    expect(find.textContaining('No shared pods in this range'), findsOneWidget);
    expect(find.byType(DropdownButton<StatsTimeRange>), findsOneWidget);
    // Not the all-time "never played" empty state.
    expect(find.textContaining('No shared pods yet'), findsNothing);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/friends_list/friend_stats/friend_stats_page_test.dart`
Expected: FAIL — no `DropdownButton<StatsTimeRange>`, `'Avg Time Alive'` not found.

- [ ] **Step 3: Add the dropdown, range wiring, empty-in-range body, and grid tuning**

In `lib/friends_list/friend_stats/view/friend_stats_page.dart`:

3a. Add the stats-overview import (for `StatsTimeRange`) with the other imports:

```dart
import 'package:magic_yeti/stats_overview/stats_overview.dart';
```

3b. Add a range-change handler to `_FriendStatsViewState` (next to `_compile`):

```dart
  void _onRangeChanged(StatsTimeRange? range) {
    if (range == null) return;
    context.read<FriendStatsBloc>().add(FriendStatsRangeChanged(range));
  }
```

3c. Pass `range` and the handler into the body. Replace the `FriendStatsLoaded` switch arm with:

```dart
              FriendStatsLoaded(:final stats, :final range) => _FriendStatsBody(
                friendName: _friendName,
                friend: widget.friend,
                stats: stats,
                range: range,
                onRangeChanged: _onRangeChanged,
              ),
```

3d. Replace the `_FriendStatsBody` class with the version below. It: keeps the "never played" empty state only for all-time-with-zero-pods; otherwise always renders the dropdown, then either the stats or an in-range-empty message; and tightens the grid.

```dart
class _FriendStatsBody extends StatelessWidget {
  const _FriendStatsBody({
    required this.friendName,
    required this.friend,
    required this.stats,
    required this.range,
    required this.onRangeChanged,
  });

  final String friendName;
  final FriendModel? friend;
  final FriendHeadToHead stats;
  final StatsTimeRange range;
  final ValueChanged<StatsTimeRange?> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    // No shared pods in the full history: the "go tag them" empty state. There
    // is nothing to filter, so the dropdown is omitted here.
    if (stats.sharedPods == 0 && range == StatsTimeRange.allTime) {
      return _EmptyState(friendName: friendName);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _RangeDropdown(range: range, onChanged: onRangeChanged),
          ),
          const SizedBox(height: 8),
          _Header(friendName: friendName, friend: friend, stats: stats),
          const SizedBox(height: 16),
          if (stats.sharedPods == 0)
            const _NoPodsInRange()
          else ...[
            LedgerHeroTile(stats: stats, friendName: friendName),
            const SizedBox(height: 16),
            // The grid is intrinsically sized inside a scroll view. Tighter
            // spacing and a shorter cell keep the cards close together.
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
              children: buildFriendStatTiles(stats),
            ),
          ],
        ],
      ),
    );
  }
}

/// Right-aligned time-range selector, styled like the home stats dropdown.
class _RangeDropdown extends StatelessWidget {
  const _RangeDropdown({required this.range, required this.onChanged});

  final StatsTimeRange range;
  final ValueChanged<StatsTimeRange?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<StatsTimeRange>(
      value: range,
      dropdownColor: Colors.grey[900],
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
      underline: Container(height: 1, color: Colors.blueGrey.withAlpha(100)),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
      items: StatsTimeRange.values
          .map(
            (r) => DropdownMenuItem<StatsTimeRange>(
              value: r,
              child: Text(r.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// Shown when the selected range has no shared pods but the friendship does —
/// distinct from [_EmptyState], and leaves the dropdown visible to widen out.
class _NoPodsInRange extends StatelessWidget {
  const _NoPodsInRange();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          const Icon(
            Icons.filter_alt_off_outlined,
            size: 48,
            color: AppColors.tertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'No shared pods in this range',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Try a wider time range.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

Leave `_Header` and `_EmptyState` unchanged.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/friends_list/friend_stats/friend_stats_page_test.dart`
Expected: PASS (all tests).

- [ ] **Step 5: Run the full friend_stats suite and analyze**

Run: `flutter test test/friends_list/friend_stats/`
Expected: PASS.

Run: `flutter analyze lib/friends_list/friend_stats`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/friends_list/friend_stats/view/friend_stats_page.dart \
        test/friends_list/friend_stats/friend_stats_page_test.dart
git commit -m "feat: time-range filter and tighter grid on friend head-to-head page"
```

---

## Task 4: Manual verification in the running app

**Files:** none (verification only).

- [ ] **Step 1: Run the app (development flavor)**

Run: `flutter run --flavor development --target lib/main_development.dart`

- [ ] **Step 2: Verify each change**

- Open a friend with shared pods (e.g. Cope357x). Confirm:
  - The range dropdown appears top-right and defaults to "All Time".
  - Tiles are cards with a caption line ("You · Them · Field", "You / Them survived", etc.) and sit close together (no large vertical gaps).
  - Changing the range to "Last 3 Months"/"Last 30 Days" updates the header pod count, the Ledger, and the tiles.
  - Narrowing to a range with no shared pods shows "No shared pods in this range" with the dropdown still visible; widening restores the stats.
- Open a friend you have never shared a pod with: the original "No shared pods yet" empty state still shows.

- [ ] **Step 3: Confirm no regression on home stats**

Open the home stats overview; confirm its dropdown and tiles are unchanged.

---

## Self-Review

**Spec coverage:**
- Date filter drives whole page → Task 1 (bloc filter) + Task 3 (dropdown, header/Ledger/tiles all fed by filtered `compute`). ✓
- Empty-in-range vs never-played → Task 3 `_NoPodsInRange` vs `_EmptyState`, gated on `range == allTime`. ✓
- Tighter 3-column grid → Task 3 `childAspectRatio`/spacing + Card-filling `FriendStatCard`. ✓
- Descriptive cards with captions → Task 2 `FriendStatCard` + caption table. ✓
- `StatsWidget` untouched, calculator/model untouched → confirmed (only friend_stats files modified). ✓
- Reuse `StatsTimeRange` → imported, not redefined. ✓

**Placeholder scan:** No TBD/TODO; all steps carry full code. `childAspectRatio: 1` is a concrete starting value; Task 4 Step 2 is the visual check that confirms/adjusts it (adjust only if cards clip — a one-line change, not a placeholder). ✓

**Type consistency:** `FriendStatsRangeChanged(StatsTimeRange)`, `FriendStatsLoaded(stats, {range})`, `FriendStatCard({title, stat, caption, tooltip})`, `buildFriendStatTiles(FriendHeadToHead)` used identically across tasks and tests. ✓
