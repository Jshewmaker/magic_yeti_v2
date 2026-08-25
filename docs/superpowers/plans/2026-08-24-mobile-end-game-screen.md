# Mobile End-Game Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `GameOverPage` usable on phones — portrait, scrollable, with a pinned action bar — without changing how it looks on tablets.

**Architecture:** `GameOverView` becomes an `AdaptiveLayout` over shared content widgets extracted out of today's 964-line `game_over_page.dart`. The tablet shell keeps its current `Column → Row(5:4)` composition verbatim. The phone shell is a fixed header, a `CustomScrollView` (with `SliverReorderableList` for standings), and a pinned action bar, locked to portrait.

**Tech Stack:** Flutter, `flutter_bloc`, `app_ui` (`AdaptiveLayout`, `OrientationLock`, `DeviceInfoProvider`), `go_router`, `flutter_test`, `bloc_test`, `mocktail`.

**Spec:** `docs/superpowers/specs/2026-08-24-mobile-end-game-screen-design.md`

## Global Constraints

- Lints are `very_good_analysis` with `public_member_api_docs: false` and `omit_local_variable_types: ignore` (`analysis_options.yaml`). `flutter analyze` must be clean after every task.
- **No changes to `GameOverBloc`, `GameOverState`, or `GameOverEvent`.** They already expose everything both shells need.
- **No changes to `test/helpers/pump_app.dart`.** Many other tests depend on it.
- Preserve `ValueKey('game_over_account_owner_dropdown')` verbatim — existing tests assert on it.
- Every existing assertion in `test/life_counter/view/game_over_page_test.dart` stays byte-for-byte unchanged. Only the two pump helpers gain a `DeviceInfoProvider` wrapper (Task 1).
- Tablet appearance must not change. The existing tablet tests are the regression gate.
- Phone breakpoint is `shortestSide < 600` (`AppBreakpoints.tablet`). Never hardcode 600.
- New ARB keys require `flutter gen-l10n --arb-dir="lib/l10n/arb"` before `flutter analyze`.
- Commit after every task.

## File Structure

| File | Responsibility |
|---|---|
| `lib/life_counter/view/game_over_page.dart` | MODIFY — `GameOverPage`, `GameOverView`, the two `AdaptiveLayout` shells. Nothing else. |
| `lib/life_counter/widgets/game_over/game_over_tokens.dart` | CREATE — `GameOverTokens` colors + placement helpers. |
| `lib/life_counter/widgets/game_over/game_over_header.dart` | CREATE — `GameOverHeader`, `RestoreGameButton`. |
| `lib/life_counter/widgets/game_over/game_over_winner_hero.dart` | CREATE — `GameOverWinnerHero`, `formatGameDuration`. |
| `lib/life_counter/widgets/game_over/game_over_standings.dart` | CREATE — `GameOverStandingsPanel`, `GameOverSectionLabel`, `StandingRow`. |
| `lib/life_counter/widgets/game_over/game_over_details.dart` | CREATE — `GameOverDetailsPanel`, `GameOverDetailsFields`, `GameOverFieldLabel`, `FirstPlayerDropdown`, `AccountOwnerDropdown`. |
| `lib/life_counter/widgets/game_over/game_over_actions.dart` | CREATE — `GameOverActionBar`, `GameOverActionButton`, `GameOverRequiredHint`. |
| `lib/life_counter/widgets/game_over/game_over.dart` | CREATE — barrel. |
| `lib/life_counter/widgets/widgets.dart` | MODIFY — export the barrel. |
| `lib/l10n/arb/app_en.arb` | MODIFY — add `accountOwnerShort`. |
| `test/life_counter/view/game_over_page_test.dart` | MODIFY — `DeviceInfoProvider` wrappers only. |
| `test/life_counter/widgets/game_over/game_over_header_test.dart` | CREATE |
| `test/life_counter/widgets/game_over/standing_row_test.dart` | CREATE |
| `test/life_counter/widgets/game_over/game_over_winner_hero_test.dart` | CREATE |
| `test/life_counter/widgets/game_over/game_over_details_fields_test.dart` | CREATE |
| `test/life_counter/widgets/game_over/game_over_actions_test.dart` | CREATE |
| `test/life_counter/view/game_over_page_phone_test.dart` | CREATE |

---

## Task 1: Extract widgets into `widgets/game_over/` (pure refactor)

Zero behavior change. Move code out of the 964-line page file, renaming private classes to public. The existing tablet tests are the gate: if they fail, the move was not faithful.

**Files:**
- Create: `lib/life_counter/widgets/game_over/game_over_tokens.dart`
- Create: `lib/life_counter/widgets/game_over/game_over_header.dart`
- Create: `lib/life_counter/widgets/game_over/game_over_winner_hero.dart`
- Create: `lib/life_counter/widgets/game_over/game_over_standings.dart`
- Create: `lib/life_counter/widgets/game_over/game_over_details.dart`
- Create: `lib/life_counter/widgets/game_over/game_over_actions.dart`
- Create: `lib/life_counter/widgets/game_over/game_over.dart`
- Modify: `lib/life_counter/widgets/widgets.dart`
- Modify: `lib/life_counter/view/game_over_page.dart` (delete lines 16–43 and 151–964, keep 45–150)
- Modify: `test/life_counter/view/game_over_page_test.dart:110` and `:249`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces, all imported via `package:magic_yeti/life_counter/widgets/game_over/game_over.dart`:
  - `GameOverTokens` — statics `background`, `surface`, `surfaceRaised`, `border`, `accent`, `gold`, `silver`, `bronze`, `fourth`, `textPrimary`, `textSecondary`; `static Color placementColor(int placement)`; `static String placementLabel(int placement)`
  - `GameOverHeader({required bool canRestoreGame, Key? key})`
  - `RestoreGameButton({Key? key})`
  - `GameOverWinnerHero({required Player winner, Key? key})`
  - `String formatGameDuration(int seconds)`
  - `GameOverStandingsPanel({required GameOverState state, Key? key})`
  - `StandingRow({required Player player, required int placement, Key? key})`
  - `GameOverDetailsPanel({required GameOverState state, required List<Player> players, required GameModel gameModel, Key? key})`
  - `GameOverFieldLabel({required String label, Key? key})`
  - `FirstPlayerDropdown({required String? value, required List<Player> players, required ValueChanged<String?> onChanged, Key? key})`
  - `AccountOwnerDropdown({required String? value, required List<Player> players, required String currentUserId, required ValueChanged<String?> onChanged, Key? key})`
  - `GameOverActionButton({required String label, required bool isPrimary, required bool enabled, required VoidCallback onPressed, Key? key})`

### Rename table

Apply these renames while moving. Bodies are otherwise **verbatim** — do not reformat, restyle, or "improve" them in this task.

| Old (in `game_over_page.dart`) | New | Destination |
|---|---|---|
| `_MC` (L17–43) | `GameOverTokens` | `game_over_tokens.dart` |
| `_Header` (L152–199) | `GameOverHeader` | `game_over_header.dart` |
| `_RestoreButton` (L201–233) | `RestoreGameButton` | `game_over_header.dart` |
| `_WinnerHero` (L236–396) | `GameOverWinnerHero` | `game_over_winner_hero.dart` |
| `_formatDuration` (L961–964) | `formatGameDuration` | `game_over_winner_hero.dart` |
| `_StandingsPanel` (L399–484) | `GameOverStandingsPanel` | `game_over_standings.dart` |
| `_StandingRow` (L486–600) | `StandingRow` | `game_over_standings.dart` |
| `_DetailsPanel` (L603–764) | `GameOverDetailsPanel` | `game_over_details.dart` |
| `_FieldLabel` (L767–783) | `GameOverFieldLabel` | `game_over_details.dart` |
| `_PlayerDropdown` (L785–838) | `FirstPlayerDropdown` | `game_over_details.dart` |
| `_AccountOwnerDropdown` (L840–902) | `AccountOwnerDropdown` | `game_over_details.dart` |
| `_ActionButton` (L904–958) | `GameOverActionButton` | `game_over_actions.dart` |

Every `_MC.` reference in the moved bodies becomes `GameOverTokens.`. Every `_Header`, `_WinnerHero`, `_StandingsPanel`, `_StandingRow`, `_DetailsPanel`, `_FieldLabel`, `_PlayerDropdown`, `_AccountOwnerDropdown`, `_ActionButton`, `_RestoreButton`, `_formatDuration` reference becomes its new name — including the two inside `GameOverStandingsPanel`'s `proxyDecorator` and `itemBuilder`, and the `'proxy_$index'` key stays as-is.

Constructors that were private-class-positional stay the same shape; just add `super.key` where the old class did not have it (`GameOverHeader`, `RestoreGameButton`, `GameOverWinnerHero`, `GameOverStandingsPanel`, `GameOverDetailsPanel`, `GameOverFieldLabel`, `FirstPlayerDropdown`, `GameOverActionButton`). `StandingRow` and `AccountOwnerDropdown` already take `super.key`.

- [ ] **Step 1: Create the tokens file**

`lib/life_counter/widgets/game_over/game_over_tokens.dart`:

```dart
import 'package:flutter/material.dart';

class GameOverTokens {
  const GameOverTokens._();

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
```

- [ ] **Step 2: Move the five widget groups**

Cut each range from `game_over_page.dart` into its destination file per the rename table. Add the imports each file actually needs — the analyzer will tell you which are missing or unused. For reference, the full import set currently at the top of `game_over_page.dart` is:

```dart
import 'dart:ui';

import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/home/home.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/view/game_page.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:player_repository/player_repository.dart';
```

`dart:ui` is needed only by `game_over_standings.dart` (for `lerpDouble`).

- [ ] **Step 3: Create the barrel**

`lib/life_counter/widgets/game_over/game_over.dart`:

```dart
export 'game_over_actions.dart';
export 'game_over_details.dart';
export 'game_over_header.dart';
export 'game_over_standings.dart';
export 'game_over_tokens.dart';
export 'game_over_winner_hero.dart';
```

- [ ] **Step 4: Export the barrel from the feature barrel**

`lib/life_counter/widgets/widgets.dart` becomes:

```dart
export 'center_control_column.dart';
export 'game_over/game_over.dart';
export 'life_counter_widget.dart';
export 'timer_widget.dart';
```

- [ ] **Step 5: Trim the page file**

`game_over_page.dart` keeps only `GameOverPage` and `GameOverView` (old lines 45–150) plus its imports, with this added:

```dart
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
```

Inside `GameOverView.build`, the widget references become `GameOverHeader`, `GameOverWinnerHero`, `GameOverStandingsPanel`, `GameOverDetailsPanel`, and `GameOverTokens.background`. Structure is otherwise untouched.

- [ ] **Step 6: Add `DeviceInfoProvider` to both test pump helpers**

This is the only test change in this task. It is a no-op today and prevents an assertion failure in Task 7.

In `test/life_counter/view/game_over_page_test.dart`, add the import:

```dart
import 'package:app_ui/app_ui.dart';
```

In `pumpGameOverView` (around line 115), wrap the subject:

```dart
      await tester.pumpApp(
        DeviceInfoProvider.fromMediaQuery(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AppBloc>.value(value: appBloc),
              BlocProvider<GameBloc>.value(value: gameBloc),
              BlocProvider<TimerBloc>.value(value: timerBloc),
              BlocProvider<GameOverBloc>.value(value: gameOverBloc),
            ],
            child: RepositoryProvider<PlayerRepository>.value(
              value: playerRepository,
              child: const GameOverView(),
            ),
          ),
        ),
      );
```

In `pumpRoutedGameOverView` (around line 260), wrap the route builder's subject the same way:

```dart
            builder: (context, state) => DeviceInfoProvider.fromMediaQuery(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<AppBloc>.value(value: appBloc),
                  BlocProvider<GameBloc>.value(value: gameBloc),
                  BlocProvider<TimerBloc>.value(value: timerBloc),
                  BlocProvider<GameOverBloc>.value(value: bloc),
                ],
                child: RepositoryProvider<PlayerRepository>.value(
                  value: playerRepository,
                  child: const GameOverView(),
                ),
              ),
            ),
```

Do not touch any `expect(...)` in this file.

- [ ] **Step 7: Verify the refactor changed nothing**

```bash
flutter analyze && flutter test test/life_counter/view/game_over_page_test.dart
```

Expected: analyze reports no issues; every test in the file passes. If any assertion fails, the move was not faithful — diff the moved body against `git show HEAD:lib/life_counter/view/game_over_page.dart`.

- [ ] **Step 8: Commit**

```bash
git add lib/life_counter test/life_counter
git commit -m "refactor: split game over page into widget files"
```

---

## Task 2: Header uses a `Stack`, not fixed-width reservations

Today's header reserves `SizedBox(width: 140)` on both sides of a centered title. On a 390pt phone that leaves 95pt for the title.

**Files:**
- Modify: `lib/life_counter/widgets/game_over/game_over_header.dart`
- Test: `test/life_counter/widgets/game_over/game_over_header_test.dart` (create)

**Interfaces:**
- Consumes: `GameOverTokens` (Task 1).
- Produces: `GameOverHeader({required bool canRestoreGame, bool compact = false, Key? key})`. `compact: true` renders the restore control icon-only.

- [ ] **Step 1: Write the failing test**

`test/life_counter/widgets/game_over/game_over_header_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGameBloc extends MockBloc<GameEvent, GameState>
    implements GameBloc {}

class _MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

void main() {
  group('GameOverHeader', () {
    late _MockGameBloc gameBloc;
    late _MockTimerBloc timerBloc;

    setUp(() {
      gameBloc = _MockGameBloc();
      timerBloc = _MockTimerBloc();
      when(() => gameBloc.state).thenReturn(const GameState());
      when(() => timerBloc.state).thenReturn(const TimerState());
    });

    Future<void> pumpHeader(
      WidgetTester tester, {
      required Size size,
      required bool compact,
      bool canRestoreGame = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<GameBloc>.value(value: gameBloc),
            BlocProvider<TimerBloc>.value(value: timerBloc),
          ],
          child: Scaffold(
            body: GameOverHeader(
              canRestoreGame: canRestoreGame,
              compact: compact,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('does not overflow at phone width', (tester) async {
      await pumpHeader(
        tester,
        size: const Size(390, 844),
        compact: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('MATCH COMPLETE'), findsOneWidget);
    });

    testWidgets('compact hides the restore label but keeps the control',
        (tester) async {
      await pumpHeader(
        tester,
        size: const Size(390, 844),
        compact: true,
      );

      expect(find.text('RESTORE GAME'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('non-compact keeps the restore label', (tester) async {
      await pumpHeader(
        tester,
        size: const Size(1280, 800),
        compact: false,
      );

      expect(find.text('RESTORE GAME'), findsOneWidget);
    });

    testWidgets('omits the restore control when the game cannot be restored',
        (tester) async {
      await pumpHeader(
        tester,
        size: const Size(1280, 800),
        compact: false,
        canRestoreGame: false,
      );

      expect(find.text('RESTORE GAME'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

```bash
flutter test test/life_counter/widgets/game_over/game_over_header_test.dart
```

Expected: compile error — `GameOverHeader` has no named parameter `compact`.

- [ ] **Step 3: Rewrite `GameOverHeader`**

Replace the `GameOverHeader` class body in `game_over_header.dart` with:

```dart
class GameOverHeader extends StatelessWidget {
  const GameOverHeader({
    required this.canRestoreGame,
    this.compact = false,
    super.key,
  });

  final bool canRestoreGame;

  /// Renders the restore control icon-only so the title keeps the full width.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 20,
        vertical: compact ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: GameOverTokens.border)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'MATCH COMPLETE',
                style: TextStyle(
                  color: GameOverTokens.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.l10n.gameOverTitle,
                style: const TextStyle(
                  color: GameOverTokens.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (canRestoreGame)
            Align(
              alignment: Alignment.centerLeft,
              child: RestoreGameButton(compact: compact),
            ),
        ],
      ),
    );
  }
}
```

The `Stack` sizes to the `Column`, so the header height is unchanged on tablet. The restore control now overlays rather than reserving width, so the title is always truly centered on the full width.

- [ ] **Step 4: Add the `compact` branch to `RestoreGameButton`**

In the same file, change the constructor and `build` of `RestoreGameButton`. The `onPressed` body is **unchanged** — extract it to a method so both branches share it:

```dart
class RestoreGameButton extends StatelessWidget {
  const RestoreGameButton({this.compact = false, super.key});

  final bool compact;

  void _restore(BuildContext context) {
    final l10n = context.l10n;
    context.read<TimerBloc>().add(const TimerStartEvent());
    context.read<GameBloc>()
      ..add(const GameRestoreRequested())
      ..add(const GameResumeEvent());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.gameRestoredMessage)),
    );
    context.go(GamePage.routePath);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: () => _restore(context),
        color: GameOverTokens.textSecondary,
        tooltip: 'Restore game',
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
      );
    }

    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: GameOverTokens.textSecondary,
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
      onPressed: () => _restore(context),
    );
  }
}
```

- [ ] **Step 5: Run the tests**

```bash
flutter analyze && flutter test test/life_counter/widgets/game_over/game_over_header_test.dart test/life_counter/view/game_over_page_test.dart
```

Expected: all pass. The tablet page test proves the header change did not alter tablet rendering.

- [ ] **Step 6: Commit**

```bash
git add lib/life_counter test/life_counter
git commit -m "fix: center game over header without fixed-width reservations"
```

---

## Task 3: Harden `StandingRow` — ellipsis, image errors, real drag handle

**Files:**
- Modify: `lib/life_counter/widgets/game_over/game_over_standings.dart`
- Test: `test/life_counter/widgets/game_over/standing_row_test.dart` (create)

**Interfaces:**
- Consumes: `GameOverTokens`, `StandingRow` (Task 1).
- Produces: `StandingRow({required Player player, required int placement, int? dragIndex, Key? key})`. When `dragIndex` is non-null the drag handle becomes a `ReorderableDragStartListener` for that index; when null the handle is inert (used by `proxyDecorator`, which renders outside the reorderable's scope).
- Also produces `GameOverSectionLabel({required String label, Widget? trailing, Key? key})` for reuse by the phone shell in Task 7.

- [ ] **Step 1: Write the failing test**

`test/life_counter/widgets/game_over/standing_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:player_repository/player_repository.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('StandingRow', () {
    const base = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    Future<void> pumpRow(
      WidgetTester tester,
      Player player, {
      int? dragIndex,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverReorderableList(
                itemCount: 1,
                onReorder: (_, __) {},
                itemBuilder: (context, index) => StandingRow(
                  key: ValueKey(player.id),
                  player: player,
                  placement: 1,
                  dragIndex: dragIndex,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a very long player name ellipsizes instead of overflowing',
        (tester) async {
      await pumpRow(
        tester,
        base.copyWith(
          name: 'Bartholomew Maximilian Featherstonehaugh The Third',
        ),
        dragIndex: 0,
      );

      expect(tester.takeException(), isNull);

      final nameText = tester.widget<Text>(
        find.text('Bartholomew Maximilian Featherstonehaugh The Third'),
      );
      expect(nameText.overflow, TextOverflow.ellipsis);
      expect(nameText.maxLines, 1);
    });

    testWidgets('exposes a drag listener when dragIndex is provided',
        (tester) async {
      await pumpRow(tester, base, dragIndex: 0);

      expect(find.byType(ReorderableDragStartListener), findsOneWidget);
    });

    testWidgets('has no drag listener when dragIndex is null', (tester) async {
      await pumpRow(tester, base);

      expect(find.byType(ReorderableDragStartListener), findsNothing);
      expect(find.byIcon(Icons.drag_handle_rounded), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

```bash
flutter test test/life_counter/widgets/game_over/standing_row_test.dart
```

Expected: compile error — `StandingRow` has no named parameter `dragIndex`.

- [ ] **Step 3: Update `StandingRow`**

Change the constructor:

```dart
class StandingRow extends StatelessWidget {
  const StandingRow({
    required this.player,
    required this.placement,
    this.dragIndex,
    super.key,
  });

  final Player player;
  final int placement;

  /// Index this row occupies in the surrounding reorderable list. When set,
  /// the grip becomes the only thing that starts a drag, leaving the rest of
  /// the row free to scroll the page. Null inside `proxyDecorator`, which
  /// renders outside the reorderable's scope.
  final int? dragIndex;
```

Inside `build`, replace the commander-art `Opacity(...)` block with one that survives a failed fetch:

```dart
          if (hasArt)
            Opacity(
              opacity: 0.2,
              child: Image.network(
                player.commander!.imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
```

Give both name `Text` widgets bounds:

```dart
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GameOverTokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (player.commander?.name.isNotEmpty ?? false)
                      Text(
                        player.commander!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: GameOverTokens.textSecondary,
                          fontSize: 11,
                        ),
                      ),
```

Replace the trailing drag-handle `Padding` with:

```dart
              _DragHandle(dragIndex: dragIndex),
```

And add, at the bottom of the file:

```dart
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.dragIndex});

  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    const handle = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Icon(
        Icons.drag_handle_rounded,
        color: GameOverTokens.textSecondary,
        size: 20,
      ),
    );

    final index = dragIndex;
    if (index == null) return handle;

    return ReorderableDragStartListener(index: index, child: handle);
  }
}
```

- [ ] **Step 4: Extract the proxy decorator so both shells share it**

The tablet panel's `proxyDecorator` closure has to be reused by the phone shell
in Task 7. Lift it to a top-level function in `game_over_standings.dart`:

```dart
ReorderItemProxyDecorator standingsProxyDecorator(List<Player> standings) {
  return (child, index, animation) {
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
          child: StandingRow(
            key: ValueKey('proxy_$index'),
            player: standings[index],
            placement: index + 1,
          ),
        );
      },
    );
  };
}
```

Note it passes no `dragIndex`. The proxy renders outside the reorderable's
scope, and a `ReorderableDragStartListener` there would throw.

In `GameOverStandingsPanel`, replace the inline `proxyDecorator:` closure with:

```dart
            proxyDecorator: standingsProxyDecorator(state.standings),
```

- [ ] **Step 5: Add `GameOverSectionLabel` for the phone shell**

Also in `game_over_standings.dart`:

```dart
class GameOverSectionLabel extends StatelessWidget {
  const GameOverSectionLabel({required this.label, this.trailing, super.key});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GameOverTokens.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}
```

- [ ] **Step 6: Wire the handle into the tablet standings panel**

In `GameOverStandingsPanel`, the `itemBuilder` passes the index:

```dart
            itemBuilder: (context, index) {
              final player = state.standings[index];
              return StandingRow(
                key: ValueKey(player.id),
                player: player,
                placement: index + 1,
                dragIndex: index,
              );
            },
```

Because the handle is now the only drag trigger, also set
`buildDefaultDragHandles: false` on the `ReorderableListView.builder`. By
default it wraps every row in a `ReorderableDelayedDragStartListener` on touch
platforms, which is exactly the long-press-anywhere behavior we are removing.

- [ ] **Step 7: Run the tests**

```bash
flutter analyze && flutter test test/life_counter/widgets/game_over/ test/life_counter/view/game_over_page_test.dart
```

Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add lib/life_counter test/life_counter
git commit -m "fix: bound standing row text and make the grip the drag trigger"
```

---

## Task 4: `GameOverWinnerHero` compact variant

**Files:**
- Modify: `lib/life_counter/widgets/game_over/game_over_winner_hero.dart`
- Test: `test/life_counter/widgets/game_over/game_over_winner_hero_test.dart` (create)

**Interfaces:**
- Consumes: `GameOverTokens`, `formatGameDuration` (Task 1).
- Produces: `GameOverWinnerHero({required Player winner, bool compact = false, Key? key})`.

- [ ] **Step 1: Write the failing test**

`test/life_counter/widgets/game_over/game_over_winner_hero_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../../helpers/pump_app.dart';

class _MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

void main() {
  group('GameOverWinnerHero', () {
    late _MockTimerBloc timerBloc;

    const base = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    setUp(() {
      timerBloc = _MockTimerBloc();
      when(() => timerBloc.state).thenReturn(
        const TimerState(elapsedSeconds: 3600 + 23 * 60),
      );
    });

    Future<void> pumpHero(
      WidgetTester tester, {
      required bool compact,
      required Size size,
      Player? winner,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        BlocProvider<TimerBloc>.value(
          value: timerBloc,
          child: Scaffold(
            body: SingleChildScrollView(
              child: GameOverWinnerHero(
                winner: winner ?? base,
                compact: compact,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('compact renders at phone width without overflow',
        (tester) async {
      await pumpHero(tester, compact: true, size: const Size(390, 844));

      expect(tester.takeException(), isNull);
      expect(find.text('1h 23m'), findsOneWidget);
    });

    testWidgets('compact ellipsizes a long winner name over two lines',
        (tester) async {
      const longName = 'Bartholomew Maximilian Featherstonehaugh The Third';
      await pumpHero(
        tester,
        compact: true,
        size: const Size(390, 844),
        winner: base.copyWith(name: longName),
      );

      expect(tester.takeException(), isNull);

      final nameText = tester.widget<Text>(find.text(longName));
      expect(nameText.maxLines, 2);
      expect(nameText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('non-compact keeps the boxed duration chip', (tester) async {
      await pumpHero(tester, compact: false, size: const Size(1280, 800));

      expect(tester.takeException(), isNull);
      expect(find.text('1h 23m'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

```bash
flutter test test/life_counter/widgets/game_over/game_over_winner_hero_test.dart
```

Expected: compile error — `GameOverWinnerHero` has no named parameter `compact`.

- [ ] **Step 3: Restructure the hero**

Replace the whole `GameOverWinnerHero` class with this. The tablet branch (`compact: false`) is the existing content verbatim; the phone branch is new. The shared frame — art, scrim, gold bar, border — is written once.

```dart
class GameOverWinnerHero extends StatelessWidget {
  const GameOverWinnerHero({
    required this.winner,
    this.compact = false,
    super.key,
  });

  final Player winner;

  /// Stacks the winner details above an inline duration instead of putting a
  /// boxed duration chip beside them. Phone layout.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasArt = winner.commander?.imageUrl.isNotEmpty ?? false;

    return Container(
      height: compact ? 180 : 200,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: GameOverTokens.surfaceRaised,
        border: Border.all(
          color: GameOverTokens.gold.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasArt) ...[
            Image.network(
              winner.commander!.imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
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
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [GameOverTokens.gold, Color(0x44FFB020)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 18 : 28,
              vertical: 20,
            ),
            child: compact
                ? _CompactContent(winner: winner)
                : _WideContent(winner: winner),
          ),
        ],
      ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          color: GameOverTokens.gold,
          size: 18,
        ),
        const SizedBox(width: 7),
        Text(
          context.l10n.winner.toUpperCase(),
          style: const TextStyle(
            color: GameOverTokens.gold,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _CompactContent extends StatelessWidget {
  const _CompactContent({required this.winner});

  final Player winner;

  @override
  Widget build(BuildContext context) {
    final elapsed = context.watch<TimerBloc>().state.elapsedSeconds;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WinnerBanner(),
        const SizedBox(height: 6),
        Text(
          winner.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GameOverTokens.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        if (winner.commander?.name.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            winner.commander!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GameOverTokens.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              color: GameOverTokens.textSecondary,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              formatGameDuration(elapsed),
              style: const TextStyle(
                color: GameOverTokens.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

And `_WideContent` — the tablet path. This is the old `Row` body verbatim,
with two deltas: it uses `const _WinnerBanner()` in place of the inline trophy
row, and `winner.name` gains `maxLines`/`overflow`. Nothing else moves.

```dart
class _WideContent extends StatelessWidget {
  const _WideContent({required this.winner});

  final Player winner;

  @override
  Widget build(BuildContext context) {
    final elapsed = context.watch<TimerBloc>().state.elapsedSeconds;
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WinnerBanner(),
              const SizedBox(height: 6),
              Text(
                winner.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GameOverTokens.textPrimary,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GameOverTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GameOverTokens.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.gameDuration.toUpperCase(),
                style: const TextStyle(
                  color: GameOverTokens.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                formatGameDuration(elapsed),
                style: const TextStyle(
                  color: GameOverTokens.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the tests**

```bash
flutter analyze && flutter test test/life_counter/widgets/game_over/ test/life_counter/view/game_over_page_test.dart
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/life_counter test/life_counter
git commit -m "feat: add compact winner hero for phone layout"
```

---

## Task 5: `accountOwnerShort` string and shared details fields

**Files:**
- Modify: `lib/l10n/arb/app_en.arb`
- Modify: `lib/life_counter/widgets/game_over/game_over_details.dart`
- Test: `test/life_counter/widgets/game_over/game_over_details_fields_test.dart` (create)

**Interfaces:**
- Consumes: `GameOverFieldLabel`, `FirstPlayerDropdown`, `AccountOwnerDropdown`, `GameOverTokens` (Task 1).
- Produces: `GameOverDetailsFields({required GameOverState state, required List<Player> players, required String currentUserId, bool compact = false, Key? key})` — just the two labelled dropdowns, no card, no `Spacer`, no buttons. `GameOverDetailsPanel` (tablet) now composes it.

- [ ] **Step 1: Add the ARB key**

In `lib/l10n/arb/app_en.arb`, next to the existing `"accountOwner"` entry (line ~452), add:

```json
  "accountOwnerShort": "Account Owner",
  "@accountOwnerShort": {
    "description": "Short field label for the account owner dropdown, used on phones where the full sentence would wrap to three lines."
  },
```

- [ ] **Step 2: Regenerate localizations**

```bash
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

Expected: completes without error; `l10n.accountOwnerShort` resolves.

- [ ] **Step 3: Extract `GameOverDetailsFields`**

Add to `game_over_details.dart`:

```dart
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
```

- [ ] **Step 4: Have the tablet panel use it**

In `GameOverDetailsPanel.build`, replace everything between the `'MATCH DETAILS'` label and the `Spacer()` with:

```dart
          GameOverDetailsFields(
            state: state,
            players: players,
            currentUserId: context.read<AppBloc>().state.user.id,
          ),
```

Everything else in `GameOverDetailsPanel` — the card decoration, the `'MATCH DETAILS'` label, the `Spacer()`, the required-fields hint, and the button `Row` — stays exactly as it is. `compact` is left at its default `false`, so the tablet keeps the full sentence.

- [ ] **Step 5: Test the extracted fields**

`test/life_counter/widgets/game_over/game_over_details_fields_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../../helpers/pump_app.dart';

class _MockGameOverBloc extends MockBloc<GameOverEvent, GameOverState>
    implements GameOverBloc {}

void main() {
  group('GameOverDetailsFields', () {
    late _MockGameOverBloc bloc;

    const base = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    final players = [
      base.copyWith(id: 'a', name: 'Alice', placement: const Value(1)),
      base.copyWith(id: 'b', name: 'Bob', placement: const Value(2)),
    ];

    late GameOverState state;

    setUp(() {
      bloc = _MockGameOverBloc();
      state = GameOverState(
        standings: players,
        selectedPlayerId: null,
        firstPlayerId: null,
      );
      when(() => bloc.state).thenReturn(state);
    });

    Future<void> pumpFields(
      WidgetTester tester, {
      required bool compact,
    }) async {
      tester.view.physicalSize =
          compact ? const Size(390, 844) : const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        BlocProvider<GameOverBloc>.value(
          value: bloc,
          child: Scaffold(
            body: SingleChildScrollView(
              child: GameOverDetailsFields(
                state: state,
                players: players,
                currentUserId: 'host',
                compact: compact,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders both dropdowns at phone width without overflow',
        (tester) async {
      await pumpFields(tester, compact: true);

      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('game_over_account_owner_dropdown')),
        findsOneWidget,
      );
    });

    testWidgets('compact uses the short account owner label', (tester) async {
      await pumpFields(tester, compact: true);

      expect(find.text('Account Owner'), findsOneWidget);
    });

    testWidgets('non-compact keeps the full account owner sentence',
        (tester) async {
      await pumpFields(tester, compact: false);

      expect(find.text('Account Owner'), findsNothing);
      expect(
        find.textContaining('Please select the account owner'),
        findsOneWidget,
      );
    });

    testWidgets('picking a first player dispatches UpdateFirstPlayerEvent',
        (tester) async {
      await pumpFields(tester, compact: true);

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();

      verify(() => bloc.add(const UpdateFirstPlayerEvent('a'))).called(1);
    });

    testWidgets('picking an account owner dispatches UpdateSelectedPlayerEvent',
        (tester) async {
      await pumpFields(tester, compact: true);

      await tester.tap(
        find.byKey(const ValueKey('game_over_account_owner_dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').last);
      await tester.pumpAndSettle();

      verify(() => bloc.add(const UpdateSelectedPlayerEvent('b'))).called(1);
    });
  });
}
```

- [ ] **Step 6: Run the tests**

```bash
flutter analyze && flutter test test/life_counter/widgets/game_over/ test/life_counter/view/game_over_page_test.dart
```

Expected: all pass — in particular the two existing `game_over_account_owner_dropdown` tests, which prove the key survived the extraction.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n lib/life_counter test/life_counter
git commit -m "feat: extract shared game over detail fields with a short phone label"
```

---

## Task 6: `GameOverActionBar`

**Files:**
- Modify: `lib/life_counter/widgets/game_over/game_over_actions.dart`
- Test: `test/life_counter/widgets/game_over/game_over_actions_test.dart` (create)

**Interfaces:**
- Consumes: `GameOverActionButton`, `GameOverTokens` (Task 1).
- Produces: `GameOverActionBar({required bool canSubmit, required VoidCallback onReturnHome, required VoidCallback onPlayAgain, bool stacked = false, Key? key})`. `stacked: true` renders full-width buttons in a `Column`, Play Again first.

- [ ] **Step 1: Write the failing test**

`test/life_counter/widgets/game_over/game_over_actions_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('GameOverActionBar', () {
    Future<void> pumpBar(
      WidgetTester tester, {
      required bool stacked,
      required bool canSubmit,
      required Size size,
      VoidCallback? onPlayAgain,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: GameOverActionBar(
              canSubmit: canSubmit,
              stacked: stacked,
              onReturnHome: () {},
              onPlayAgain: onPlayAgain ?? () {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('stacked bar fits phone width without overflow',
        (tester) async {
      await pumpBar(
        tester,
        stacked: true,
        canSubmit: true,
        size: const Size(390, 844),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows the required-fields hint only when disabled',
        (tester) async {
      await pumpBar(
        tester,
        stacked: true,
        canSubmit: false,
        size: const Size(390, 844),
      );
      expect(find.text('Fill out both fields to continue'), findsOneWidget);

      await pumpBar(
        tester,
        stacked: true,
        canSubmit: true,
        size: const Size(390, 844),
      );
      expect(find.text('Fill out both fields to continue'), findsNothing);
    });

    testWidgets('disabled buttons do not fire their callbacks',
        (tester) async {
      var played = false;
      await pumpBar(
        tester,
        stacked: true,
        canSubmit: false,
        size: const Size(390, 844),
        onPlayAgain: () => played = true,
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(played, isFalse);
    });

    testWidgets('enabled play again fires its callback', (tester) async {
      var played = false;
      await pumpBar(
        tester,
        stacked: true,
        canSubmit: true,
        size: const Size(390, 844),
        onPlayAgain: () => played = true,
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(played, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

```bash
flutter test test/life_counter/widgets/game_over/game_over_actions_test.dart
```

Expected: compile error — `GameOverActionBar` is not defined.

- [ ] **Step 3: Implement the bar**

Append to `game_over_actions.dart`:

```dart
class GameOverRequiredHint extends StatelessWidget {
  const GameOverRequiredHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          color: GameOverTokens.textSecondary,
          size: 13,
        ),
        const SizedBox(width: 6),
        Text(
          'Fill out both fields to continue',
          style: TextStyle(
            color: GameOverTokens.textSecondary.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class GameOverActionBar extends StatelessWidget {
  const GameOverActionBar({
    required this.canSubmit,
    required this.onReturnHome,
    required this.onPlayAgain,
    this.stacked = false,
    super.key,
  });

  final bool canSubmit;
  final VoidCallback onReturnHome;
  final VoidCallback onPlayAgain;

  /// Full-width buttons in a column. `RETURN TO HOME` needs ~126pt and a
  /// side-by-side phone layout leaves ~134pt, which breaks at larger text
  /// scales or in translation.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final playAgain = GameOverActionButton(
      label: l10n.playAgain,
      isPrimary: true,
      enabled: canSubmit,
      onPressed: onPlayAgain,
    );
    final returnHome = GameOverActionButton(
      label: l10n.returnToHome,
      isPrimary: false,
      enabled: canSubmit,
      onPressed: onReturnHome,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: GameOverTokens.surface,
        border: Border(top: BorderSide(color: GameOverTokens.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canSubmit) ...[
            const GameOverRequiredHint(),
            const SizedBox(height: 12),
          ],
          if (stacked) ...[
            playAgain,
            const SizedBox(height: 10),
            returnHome,
          ] else
            Row(
              children: [
                Expanded(child: returnHome),
                const SizedBox(width: 10),
                Expanded(child: playAgain),
              ],
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

```bash
flutter analyze && flutter test test/life_counter/widgets/game_over/ test/life_counter/view/game_over_page_test.dart
```

Expected: all pass. `GameOverDetailsPanel` is not touched in this task, so the tablet is unaffected.

- [ ] **Step 5: Commit**

```bash
git add lib/life_counter test/life_counter
git commit -m "feat: add game over action bar with a stacked phone variant"
```

---

## Task 7: Phone shell — `AdaptiveLayout`, portrait lock, scrolling body

The payoff task. `GameOverView` splits into two shells.

**Files:**
- Modify: `lib/life_counter/view/game_over_page.dart`
- Test: `test/life_counter/view/game_over_page_phone_test.dart` (create)

**Interfaces:**
- Consumes: everything from Tasks 1–6.
- Produces: no new public API.

- [ ] **Step 1: Write the failing tests**

`test/life_counter/view/game_over_page_phone_test.dart`:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/view/game_over_page.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:user_repository/user_repository.dart';

import '../../helpers/pump_app.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockGameBloc extends MockBloc<GameEvent, GameState>
    implements GameBloc {}

class _MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class _FakeGameModel extends Fake implements GameModel {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeGameModel()));

  group('GameOverView on a phone', () {
    late _MockAppBloc appBloc;
    late _MockGameBloc gameBloc;
    late _MockTimerBloc timerBloc;
    late PlayerRepository playerRepository;

    const base = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    final gameModel = GameModel(
      players: const [],
      startTime: DateTime(2024),
      endTime: DateTime(2024),
      winnerId: 'host-slot',
      durationInSeconds: 60,
    );

    List<Player> playersFor(int count) => [
      base.copyWith(
        id: 'host-slot',
        name: 'Host Player',
        firebaseId: () => 'host',
        placement: const Value(1),
      ),
      base.copyWith(
        id: 'slot-2',
        name: 'Second Player',
        placement: const Value(2),
      ),
      if (count == 4) ...[
        base.copyWith(
          id: 'slot-3',
          name: 'Third Player',
          placement: const Value(3),
        ),
        base.copyWith(
          id: 'slot-4',
          name: 'Fourth Player',
          placement: const Value(4),
        ),
      ],
    ];

    setUp(() {
      appBloc = _MockAppBloc();
      gameBloc = _MockGameBloc();
      timerBloc = _MockTimerBloc();
      playerRepository = PlayerRepository();

      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'host')),
      );
      when(() => gameBloc.state).thenReturn(GameState(gameModel: gameModel));
      when(() => timerBloc.state).thenReturn(
        const TimerState(elapsedSeconds: 60),
      );
    });

    Future<GameOverBloc> pumpPhoneView(
      WidgetTester tester, {
      int playerCount = 4,
      List<Player>? players,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = GameOverBloc(
        players: players ?? playersFor(playerCount),
        currentUserId: 'host',
        firebaseDatabaseRepository: _MockFirebaseDatabaseRepository(),
      );
      addTearDown(bloc.close);

      await tester.pumpApp(
        DeviceInfoProvider(
          isPhone: true,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AppBloc>.value(value: appBloc),
              BlocProvider<GameBloc>.value(value: gameBloc),
              BlocProvider<TimerBloc>.value(value: timerBloc),
              BlocProvider<GameOverBloc>.value(value: bloc),
            ],
            child: RepositoryProvider<PlayerRepository>.value(
              value: playerRepository,
              child: const GameOverView(),
            ),
          ),
        ),
      );
      await tester.pump();
      return bloc;
    }

    testWidgets('renders a 4-player game without overflow', (tester) async {
      await pumpPhoneView(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a 2-player game without overflow', (tester) async {
      await pumpPhoneView(tester, playerCount: 2);

      expect(tester.takeException(), isNull);
    });

    testWidgets('pins the action bar without scrolling', (tester) async {
      await pumpPhoneView(tester);

      expect(find.byType(GameOverActionBar), findsOneWidget);
    });

    testWidgets('does not use the tablet two-column row', (tester) async {
      await pumpPhoneView(tester);

      expect(find.byType(GameOverStandingsPanel), findsNothing);
      expect(find.byType(GameOverDetailsPanel), findsNothing);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('scrolling reveals the match details fields', (tester) async {
      await pumpPhoneView(tester);

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('game_over_account_owner_dropdown')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('every standing row is reachable by scrolling',
        (tester) async {
      await pumpPhoneView(tester);

      await tester.scrollUntilVisible(
        find.text('Fourth Player'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Fourth Player'), findsOneWidget);
    });

    testWidgets('dragging a grip reorders the standings', (tester) async {
      final bloc = await pumpPhoneView(tester);
      final before = bloc.state.standings.map((p) => p.id).toList();

      // ReorderableDragStartListener starts an immediate drag, so no
      // long-press wait. The first small move exceeds touch slop.
      final firstGrip = find.byType(ReorderableDragStartListener).first;
      final gesture = await tester.startGesture(tester.getCenter(firstGrip));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        bloc.state.standings.map((p) => p.id).toList(),
        isNot(before),
      );
    });

    testWidgets('a long player name ellipsizes rather than overflowing',
        (tester) async {
      await pumpPhoneView(
        tester,
        players: [
          base.copyWith(
            id: 'host-slot',
            name: 'Bartholomew Maximilian Featherstonehaugh The Third',
            firebaseId: () => 'host',
            placement: const Value(1),
          ),
          base.copyWith(
            id: 'slot-2',
            name: 'Second Player',
            placement: const Value(2),
          ),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  });
}
```

- [ ] **Step 2: Run them and watch them fail**

```bash
flutter test test/life_counter/view/game_over_page_phone_test.dart
```

Expected: failures — at 390×844 the current `GameOverView` renders the tablet `Row`, so `GameOverStandingsPanel` is found (the "does not use the tablet two-column row" test fails), `CustomScrollView` is not found, and the overflow tests report a `FlutterError` from `takeException()`.

- [ ] **Step 3: Split `GameOverView` into two shells**

Rewrite `GameOverView.build` so the `BlocListener` and the `gameModel`/`canRestoreGame` lookups stay exactly where they are, and only the `BlocBuilder`'s returned widget changes:

```dart
        child: BlocBuilder<GameOverBloc, GameOverState>(
          builder: (context, state) {
            return AdaptiveLayout(
              phone: (_) => _PhoneShell(
                state: state,
                gameModel: gameModel,
                canRestoreGame: canRestoreGame,
              ),
              tablet: (_) => _TabletShell(
                state: state,
                gameModel: gameModel,
                canRestoreGame: canRestoreGame,
              ),
            );
          },
        ),
```

Add `import 'package:app_ui/app_ui.dart';` to the file.

- [ ] **Step 4: Write `_TabletShell` — today's composition, unchanged**

```dart
class _TabletShell extends StatelessWidget {
  const _TabletShell({
    required this.state,
    required this.gameModel,
    required this.canRestoreGame,
  });

  final GameOverState state;
  final GameModel gameModel;
  final bool canRestoreGame;

  @override
  Widget build(BuildContext context) {
    final players = state.standings;

    return Column(
      children: [
        GameOverHeader(canRestoreGame: canRestoreGame),
        GameOverWinnerHero(winner: players.first),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: GameOverStandingsPanel(state: state),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: GameOverDetailsPanel(
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
  }
}
```

- [ ] **Step 5: Write `_PhoneShell`**

`SliverReorderableList.onReorder` uses the **same** index semantics as
`ReorderableListView.onReorder` — the latter passes the callback straight
through to the former (`flutter/src/widgets/reorderable_list.dart:466`). So
`newIndex` is still the insertion index in the pre-removal list, and
`GameOverBloc._onUpdateStandings` keeps doing the `newIndex - 1` adjustment it
already does (`lib/life_counter/bloc/game_over_bloc.dart:44`). **Do not add a
second adjustment here** — the standings would silently come out wrong.

```dart
class _PhoneShell extends StatelessWidget {
  const _PhoneShell({
    required this.state,
    required this.gameModel,
    required this.canRestoreGame,
  });

  final GameOverState state;
  final GameModel gameModel;
  final bool canRestoreGame;

  @override
  Widget build(BuildContext context) {
    final players = state.standings;
    final userId = context.read<AppBloc>().state.user.id;
    final canSubmit =
        state.selectedPlayerId != null &&
        state.firstPlayerId != null &&
        state.status != GameOverStatus.loading;

    return SafeArea(
      child: Column(
        children: [
          GameOverHeader(canRestoreGame: canRestoreGame, compact: true),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GameOverWinnerHero(
                    winner: players.first,
                    compact: true,
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: GameOverSectionLabel(
                      label: 'FINAL STANDINGS',
                      trailing: Icon(
                        Icons.drag_indicator_rounded,
                        color: GameOverTokens.textSecondary,
                        size: 15,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverReorderableList(
                    itemCount: players.length,
                    proxyDecorator: standingsProxyDecorator(players),
                    onReorder: (oldIndex, newIndex) {
                      context.read<GameOverBloc>().add(
                        UpdateStandingsEvent(
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        ),
                      );
                    },
                    itemBuilder: (context, index) => StandingRow(
                      key: ValueKey(players[index].id),
                      player: players[index],
                      placement: index + 1,
                      dragIndex: index,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GameOverSectionLabel(label: 'MATCH DETAILS'),
                        const SizedBox(height: 14),
                        GameOverDetailsFields(
                          state: state,
                          players: players,
                          currentUserId: userId,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          GameOverActionBar(
            canSubmit: canSubmit,
            stacked: true,
            onReturnHome: () => context.read<GameOverBloc>().add(
              SendGameOverStatsEvent(gameModel: gameModel, userId: userId),
            ),
            onPlayAgain: () => context.read<GameOverBloc>().add(
              SendGameOverStatsEvent(
                gameModel: gameModel,
                userId: userId,
                exitIntent: GameOverExitIntent.playAgain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Lock phones to portrait**

In `GameOverView.build`, wrap the returned `Scaffold`:

```dart
    final isPhone = DeviceInfoProvider.of(context).isPhone;

    return OrientationLock(
      orientations: isPhone ? const [DeviceOrientation.portraitUp] : null,
      child: Scaffold(
        backgroundColor: GameOverTokens.background,
        body: BlocListener<GameOverBloc, GameOverState>(
          // ... unchanged
        ),
      ),
    );
```

Add `import 'package:flutter/services.dart';`.

Note the early-return `Scaffold` for `gameModel == null` stays as it is — no orientation policy needed on a spinner.

- [ ] **Step 7: Run everything**

```bash
flutter analyze && flutter test test/life_counter/
```

Expected: the phone suite passes, and **every existing tablet test still passes**. If a tablet test fails, `_TabletShell` diverged from the original composition — diff it against `git show HEAD~6:lib/life_counter/view/game_over_page.dart`.

- [ ] **Step 8: Run the whole suite**

```bash
flutter test
```

Expected: no new failures anywhere.

- [ ] **Step 9: Commit**

```bash
git add lib/life_counter test/life_counter
git commit -m "feat: phone layout for the end game screen"
```

---

## Verification

After Task 7, confirm on a real phone simulator — the widget tests cannot catch a bad-looking layout, only a broken one.

```bash
flutter run --flavor development --target lib/main_development.dart
```

Start a 4-player game, end it, and check: portrait, header centered, hero readable, standings scroll, grip reorders while the rest of the row scrolls, both dropdowns reachable, action bar pinned above the home indicator, and the hint appears when a field is empty.
