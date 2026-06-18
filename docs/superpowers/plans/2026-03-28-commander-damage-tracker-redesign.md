# Commander Damage Tracker Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the commander damage tracker so partner commanders display side-by-side in the horizontal scroll list, and tapping anywhere increments damage with long-press revealing a decrement zone.

**Architecture:** All changes are isolated to `lib/tracker/commander_damage_tracker_widget.dart`. The `CommanderDamageTracker` widget switches its partner layout from vertical `Column` to horizontal `Row`. The `CommanderDamageButton` widget changes tap handling to always increment on tap, and uses a top/bottom split (instead of left/right) in the expanded state for increment/decrement.

**Tech Stack:** Flutter, flutter_bloc, player_repository models, mocktail for testing

**Spec:** `docs/superpowers/specs/2026-03-28-commander-damage-tracker-redesign.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/tracker/commander_damage_tracker_widget.dart` | Modify | Both changes: partner layout (lines 60-93) and tap/decrement UX (lines 118-333) |
| `test/tracker/commander_damage_tracker_widget_test.dart` | Create | Widget tests for both partner layout and tap interaction changes |

---

### Task 1: Write tests for partner side-by-side layout

**Files:**
- Create: `test/tracker/commander_damage_tracker_widget_test.dart`

- [ ] **Step 1: Create test file with mocks and helpers**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:magic_yeti/tracker/commander_damage_tracker_widget.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/models/models.dart';

class MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

class MockGameBloc extends MockBloc<GameEvent, GameState>
    implements GameBloc {}

/// Creates a test player with optional partner.
Player createTestPlayer({
  required String id,
  String name = 'Test Player',
  int color = 0xFF0000FF,
  Commander? commander,
  Commander? partner,
  List<Opponent>? opponents,
}) {
  return Player(
    id: id,
    name: name,
    playerNumber: 1,
    lifePoints: 40,
    color: color,
    commander: commander,
    partner: partner,
    opponents: opponents ?? [],
    state: PlayerModelState.active,
  );
}

Commander createTestCommander({
  String name = 'Test Commander',
  String imageUrl = 'https://example.com/image.jpg',
}) {
  return Commander(
    name: name,
    imageUrl: imageUrl,
    colors: const [],
    cardType: 'Legendary Creature',
    manaCost: '{2}{W}',
    oracleText: 'Test oracle text',
    artist: 'Test Artist',
  );
}

/// Wraps widget with required BlocProviders for testing.
Widget buildTestWidget({
  required Widget child,
  required PlayerBloc playerBloc,
  required GameBloc gameBloc,
}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<PlayerBloc>.value(value: playerBloc),
        BlocProvider<GameBloc>.value(value: gameBloc),
      ],
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  late MockPlayerBloc mockPlayerBloc;
  late MockGameBloc mockGameBloc;

  final commanderPlayer = createTestPlayer(
    id: 'target-1',
    commander: createTestCommander(name: 'Commander A'),
    opponents: [],
  );

  final partnerPlayer = createTestPlayer(
    id: 'target-2',
    commander: createTestCommander(name: 'Commander B'),
    partner: createTestCommander(name: 'Partner B'),
    opponents: [],
  );

  final ownerPlayer = createTestPlayer(
    id: 'owner',
    opponents: [
      Opponent(
        playerId: 'target-1',
        damages: [
          CommanderDamage(damageType: DamageType.commander, amount: 3),
        ],
      ),
      Opponent(
        playerId: 'target-2',
        damages: [
          CommanderDamage(damageType: DamageType.commander, amount: 5),
          CommanderDamage(damageType: DamageType.partner, amount: 2),
        ],
      ),
    ],
  );

  setUp(() {
    mockPlayerBloc = MockPlayerBloc();
    mockGameBloc = MockGameBloc();

    when(() => mockPlayerBloc.state).thenReturn(
      PlayerState(player: ownerPlayer),
    );
    when(() => mockGameBloc.state).thenReturn(
      GameState(
        playerList: [ownerPlayer, commanderPlayer, partnerPlayer],
      ),
    );
  });

  group('CommanderDamageTracker partner layout', () {
    testWidgets(
      'renders single CommanderDamageButton when no partner',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageTracker(
              playerId: 'owner',
              player: ownerPlayer,
              commanderPlayerId: 'target-1',
            ),
          ),
        );

        expect(
          find.byType(CommanderDamageButton),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders two CommanderDamageButtons in a Row when partner exists',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageTracker(
              playerId: 'owner',
              player: ownerPlayer,
              commanderPlayerId: 'target-2',
            ),
          ),
        );

        // Two buttons: one for commander, one for partner
        expect(
          find.byType(CommanderDamageButton),
          findsNWidgets(2),
        );

        // They should be in a Row, not a Column
        expect(find.byType(Row), findsWidgets);
        // Verify no Column is a direct parent of both buttons
        final row = tester.widgetList<Row>(find.byType(Row)).where((row) {
          return row.children.whereType<CommanderDamageButton>().length == 2;
        });
        expect(row, isNotEmpty);
      },
    );

    testWidgets(
      'partner container uses target player color',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageTracker(
              playerId: 'owner',
              player: ownerPlayer,
              commanderPlayerId: 'target-2',
            ),
          ),
        );

        // Find the container wrapping partner tiles
        final container = tester.widgetList<Container>(
          find.byType(Container),
        ).where((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.color == Color(partnerPlayer.color);
          }
          return false;
        });
        expect(container, isNotEmpty);
      },
    );
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/tracker/commander_damage_tracker_widget_test.dart`

Expected: The "renders two CommanderDamageButtons in a Row" test fails because the current code uses a `Column`, not a `Row`.

---

### Task 2: Implement partner side-by-side layout

**Files:**
- Modify: `lib/tracker/commander_damage_tracker_widget.dart:60-93`

- [ ] **Step 1: Change Column to Row in the hasPartner branch**

In `lib/tracker/commander_damage_tracker_widget.dart`, replace lines 60-93 (the `hasPartner` return block):

```dart
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(
        decoration: BoxDecoration(
          color: Color(targetPlayer.color),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommanderDamageButton(
                playerId: playerId,
                commanderPlayerId: commanderPlayerId,
                player: player,
                targetPlayer: targetPlayer,
                commanderDamage: commanderDamage,
                damageType: DamageType.commander,
              ),
              const SizedBox(width: 4),
              CommanderDamageButton(
                playerId: playerId,
                commanderPlayerId: commanderPlayerId,
                player: player,
                targetPlayer: targetPlayer,
                commanderDamage: partnerDamage,
                damageType: DamageType.partner,
              ),
            ],
          ),
        ),
      ),
    );
```

The only change is `Column` → `Row` (with `mainAxisSize: MainAxisSize.min`), and the `SizedBox` uses `width` instead of implicit vertical spacing.

- [ ] **Step 2: Run tests to verify they pass**

Run: `flutter test test/tracker/commander_damage_tracker_widget_test.dart`

Expected: All partner layout tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/tracker/commander_damage_tracker_widget.dart test/tracker/commander_damage_tracker_widget_test.dart
git commit -m "feat: display partner commander tiles side-by-side in horizontal scroll list"
```

---

### Task 3: Write tests for tap-anywhere-to-increment behavior

**Files:**
- Modify: `test/tracker/commander_damage_tracker_widget_test.dart`

- [ ] **Step 1: Add tap interaction tests to the test file**

Append to the `main()` function in `test/tracker/commander_damage_tracker_widget_test.dart`, after the existing group:

```dart
  group('CommanderDamageButton tap behavior', () {
    testWidgets(
      'tap anywhere on tile increments damage',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageButton(
              playerId: 'owner',
              commanderPlayerId: 'target-1',
              player: ownerPlayer,
              targetPlayer: commanderPlayer,
              commanderDamage: 3,
              damageType: DamageType.commander,
            ),
          ),
        );

        // Tap the center of the tile (not specifically right half)
        await tester.tap(find.byType(CommanderDamageButton));
        await tester.pumpAndSettle();

        verify(
          () => mockPlayerBloc.add(
            const UpdatePlayerLifeEvent(
              decrement: true,
              playerId: 'owner',
            ),
          ),
        ).called(1);
        verify(
          () => mockPlayerBloc.add(
            const PlayerCommanderDamageIncremented(
              commanderId: 'target-1',
              damageType: DamageType.commander,
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tap on left half of tile also increments (no longer decrements)',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageButton(
              playerId: 'owner',
              commanderPlayerId: 'target-1',
              player: ownerPlayer,
              targetPlayer: commanderPlayer,
              commanderDamage: 3,
              damageType: DamageType.commander,
            ),
          ),
        );

        // Tap the left side of the tile
        final buttonFinder = find.byType(CommanderDamageButton);
        final topLeft = tester.getTopLeft(buttonFinder);
        await tester.tapAt(topLeft + const Offset(5, 50));
        await tester.pumpAndSettle();

        // Should increment, NOT decrement
        verify(
          () => mockPlayerBloc.add(
            const PlayerCommanderDamageIncremented(
              commanderId: 'target-1',
              damageType: DamageType.commander,
            ),
          ),
        ).called(1);
        verifyNever(
          () => mockPlayerBloc.add(
            const PlayerCommanderDamageDecremented(
              commanderId: 'target-1',
              damageType: DamageType.commander,
            ),
          ),
        );
      },
    );
  });
```

- [ ] **Step 2: Run tests to verify the left-half test fails**

Run: `flutter test test/tracker/commander_damage_tracker_widget_test.dart`

Expected: The "tap on left half also increments" test FAILS because current code decrements on left-half tap.

---

### Task 4: Implement tap-anywhere-to-increment

**Files:**
- Modify: `lib/tracker/commander_damage_tracker_widget.dart:118-234`

- [ ] **Step 1: Simplify onTap to always increment**

In `_CommanderDamageButtonState`, replace the `onTap` handler (line 193-195) and the `_isRightHalf` method. The changes to the build method's `GestureDetector`:

Replace:
```dart
        onTapDown: (details) => _tapDownPosition = details.localPosition,
        onTap: () {
          if (isExpanded || _tapDownPosition == null) return;
          _isRightHalf(_tapDownPosition!) ? _increment() : _decrement();
        },
```

With:
```dart
        onTap: () {
          if (isExpanded) return;
          _increment();
        },
```

- [ ] **Step 2: Replace `_isRightHalf` with `_isTopHalf`**

Replace the `_isRightHalf` method (lines 176-179):

```dart
  bool _isTopHalf(Offset localPosition) {
    final box = context.findRenderObject()! as RenderBox;
    return localPosition.dy < box.size.height / 2;
  }
```

- [ ] **Step 3: Update expanded-state gesture handling**

Replace the `onLongPressDown` handler (lines 200-203):

```dart
        onLongPressDown: (details) {
          if (!isExpanded) return;
          _isTopHalf(details.localPosition) ? _increment() : _decrement();
        },
```

- [ ] **Step 4: Remove unused `_tapDownPosition` field**

Remove the field declaration (line 121):
```dart
  Offset? _tapDownPosition;
```

The `onTapDown` callback is also removed (done in Step 1).

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/tracker/commander_damage_tracker_widget_test.dart`

Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/tracker/commander_damage_tracker_widget.dart test/tracker/commander_damage_tracker_widget_test.dart
git commit -m "feat: tap anywhere to increment, remove left/right split"
```

---

### Task 5: Write tests for expanded-state decrement UI

**Files:**
- Modify: `test/tracker/commander_damage_tracker_widget_test.dart`

- [ ] **Step 1: Add expanded-state tests**

Append to `main()` after the existing groups:

```dart
  group('CommanderDamageButton expanded state', () {
    testWidgets(
      'long press expands tile and shows minus icon',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageButton(
              playerId: 'owner',
              commanderPlayerId: 'target-1',
              player: ownerPlayer,
              targetPlayer: commanderPlayer,
              commanderDamage: 3,
              damageType: DamageType.commander,
            ),
          ),
        );

        // Verify minus icon is not shown initially
        expect(find.byIcon(Icons.remove), findsNothing);

        // Long press to expand
        await tester.longPress(find.byType(CommanderDamageButton));
        await tester.pumpAndSettle();

        // Minus icon should now be visible
        expect(find.byIcon(Icons.remove), findsOneWidget);
        // Plus icon should also be visible
        expect(find.byIcon(Icons.add), findsOneWidget);
      },
    );
  });
```

- [ ] **Step 2: Run tests to verify they pass with current expand behavior**

Run: `flutter test test/tracker/commander_damage_tracker_widget_test.dart`

Expected: These tests may pass or fail depending on how the current `_CommanderIcons` renders. If they pass, proceed. If the icon arrangement test fails, that's expected — we'll fix it in Task 6.

---

### Task 6: Redesign expanded-state icons to top/bottom layout

**Files:**
- Modify: `lib/tracker/commander_damage_tracker_widget.dart:309-333`

- [ ] **Step 1: Replace `_CommanderIcons` with top/bottom vertical layout**

Replace the entire `_CommanderIcons` widget (lines 309-333):

```dart
class _CommanderIcons extends StatelessWidget {
  const _CommanderIcons({required this.animationController});

  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    if (!animationController.isCompleted) return const SizedBox.shrink();
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Icon(
              Icons.add,
              color: AppColors.white.withValues(alpha: 0.8),
              size: 24,
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.remove,
                color: AppColors.white.withValues(alpha: 0.8),
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

The bottom half has a semi-transparent dark overlay to visually distinguish the decrement zone. The `+` icon sits in the top half, the `−` icon in the bottom half.

- [ ] **Step 2: Run all tests**

Run: `flutter test test/tracker/commander_damage_tracker_widget_test.dart`

Expected: All tests PASS.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`

Expected: No new analysis issues.

- [ ] **Step 4: Commit**

```bash
git add lib/tracker/commander_damage_tracker_widget.dart test/tracker/commander_damage_tracker_widget_test.dart
git commit -m "feat: redesign expanded state with top/bottom increment/decrement zones"
```

---

### Task 7: Final verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`

Expected: All tests pass, no regressions.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`

Expected: No issues.

- [ ] **Step 3: Manual smoke test checklist**

Run the app: `flutter run --flavor development --target lib/main_development.dart`

Verify:
1. Non-partner commanders display as single tiles in the tracker (unchanged)
2. Partner commanders display as two side-by-side tiles with a shared colored background
3. Tapping anywhere on a tile in normal state increments damage and decrements life
4. Long-pressing a tile expands it with `+` on top and `−` on bottom (with dark overlay)
5. Tapping the top half of expanded tile increments
6. Tapping the bottom half of expanded tile decrements
7. Tapping outside an expanded tile collapses it
