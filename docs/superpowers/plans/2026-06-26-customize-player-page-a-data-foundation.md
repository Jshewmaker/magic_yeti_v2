# Customize Player Page — Plan A: Data Foundation & Accuracy

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the data model distinguish an attacking second commander (Partner/Doctor/Friends Forever → its own commander-damage clock) from a non-attacking Background (color identity only), and capture the card data needed to auto-detect which is which.

**Architecture:** Add a `keywords` list to `Commander` (sourced from Scryfall) and a separate `background` slot to `Player`. Add a pure `commanderPairingFor(Commander)` function in `player_repository` that classifies a commander as `none` / `partner` / `background`. Thread `background` through the existing save path. No UI changes in this plan; later plans consume these.

**Tech Stack:** Dart, Flutter, `json_serializable`/`build_runner` codegen, `equatable`, `bloc`, `flutter_test`.

## Global Constraints

- SDK floor: `>=3.8.0 <4.0.0` (from `pubspec.yaml`).
- Lints: `very_good_analysis` ^10.1.0 — trailing commas on multi-line, single quotes, `flutter analyze` must be clean.
- Models use `@JsonSerializable` with `json_serializable` codegen; regenerate with `dart run build_runner build --delete-conflicting-outputs` after model edits. Generated files are `*.g.dart`.
- `Commander` annotation is `@JsonSerializable(explicitToJson: true, includeIfNull: false)`; `Player` is `@JsonSerializable(explicitToJson: true)`.
- Backward compatibility: existing persisted games/players must deserialize unchanged (new fields default to `[]` / `null`).
- Run package-level tests from inside the package dir (`cd packages/player_repository && flutter test`).

---

### Task 1: Add `keywords` to the `Commander` model

**Files:**
- Modify: `packages/player_repository/lib/models/commander.dart`
- Regenerate: `packages/player_repository/lib/models/commander.g.dart`
- Test: `packages/player_repository/test/models/commander_test.dart` (create)

**Interfaces:**
- Produces: `Commander.keywords` (`List<String>`, defaults to `const []`), included in `fromJson`/`toJson`/`copyWith`/`props`.

- [ ] **Step 1: Write the failing test**

Create `packages/player_repository/test/models/commander_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:player_repository/player_repository.dart';

void main() {
  group('Commander keywords', () {
    Commander base() => const Commander(
          name: 'Atraxa, Praetors\' Voice',
          colors: ['W', 'U', 'B', 'G'],
          cardType: 'Legendary Creature',
          imageUrl: 'https://example.com/atraxa.jpg',
          manaCost: '{G}{W}{U}{B}',
          oracleText: 'Flying, vigilance, deathtouch, lifelink',
          artist: 'Victor Adame Minguez',
          keywords: ['Flying', 'Vigilance'],
        );

    test('round-trips keywords through JSON', () {
      final json = base().toJson();
      final restored = Commander.fromJson(json);
      expect(restored.keywords, ['Flying', 'Vigilance']);
    });

    test('defaults to empty list when keywords absent from JSON', () {
      final json = base().toJson()..remove('keywords');
      final restored = Commander.fromJson(json);
      expect(restored.keywords, isEmpty);
    });

    test('copyWith replaces keywords', () {
      final updated = base().copyWith(keywords: ['Partner']);
      expect(updated.keywords, ['Partner']);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/player_repository && flutter test test/models/commander_test.dart`
Expected: FAIL — `The named parameter 'keywords' isn't defined` (compile error).

- [ ] **Step 3: Add the field to `Commander`**

In `packages/player_repository/lib/models/commander.dart`, add the constructor parameter (after `toughness`):

```dart
    this.toughness,
    this.keywords = const [],
  });
```

Add the field declaration (after the `toughness` field, before `toJson`):

```dart
  /// Toughness (for creatures)
  final String? toughness;

  /// Scryfall keyword abilities (e.g. 'Partner', 'Friends forever').
  /// Used to auto-detect pairing capability. Defaults to empty for
  /// commanders persisted before this field existed.
  @JsonKey(defaultValue: <String>[])
  final List<String> keywords;
```

Add to `copyWith` parameters (after `String? artist,`):

```dart
    String? artist,
    List<String>? keywords,
  }) {
```

Add to the `copyWith` body (after `artist: artist ?? this.artist,`):

```dart
      artist: artist ?? this.artist,
      keywords: keywords ?? this.keywords,
    );
```

Add to `props` (after `artist,`):

```dart
        artist,
        keywords,
      ];
```

- [ ] **Step 4: Regenerate codegen**

Run: `cd packages/player_repository && dart run build_runner build --delete-conflicting-outputs`
Expected: `commander.g.dart` regenerated with `keywords` in `_$CommanderFromJson`/`_$CommanderToJson`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd packages/player_repository && flutter test test/models/commander_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Commit**

```bash
git add packages/player_repository/lib/models/commander.dart \
        packages/player_repository/lib/models/commander.g.dart \
        packages/player_repository/test/models/commander_test.dart
git commit -m "feat: add keywords field to Commander model"
```

---

### Task 2: Add `background` to the `Player` model

**Files:**
- Modify: `packages/player_repository/lib/models/player.dart`
- Regenerate: `packages/player_repository/lib/models/player.g.dart`
- Test: `packages/player_repository/test/models/player_background_test.dart` (create)

**Interfaces:**
- Produces: `Player.background` (`Commander?`); `copyWith({Commander? Function()? background})` (function-wrapper style, matching the existing `partner` pattern so an explicit `null` can be set).

- [ ] **Step 1: Write the failing test**

Create `packages/player_repository/test/models/player_background_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:player_repository/player_repository.dart';

void main() {
  Commander commander(String name) => Commander(
        name: name,
        colors: const ['B'],
        cardType: 'Legendary Enchantment — Background',
        imageUrl: 'https://example.com/$name.jpg',
        manaCost: '',
        oracleText: '',
        artist: 'Artist',
      );

  Player base() => Player(
        id: 'p1',
        name: 'Sarah',
        playerNumber: 0,
        lifePoints: 40,
        color: 0xFF378ADD,
        opponents: const [],
        state: PlayerModelState.active,
      );

  group('Player.background', () {
    test('defaults to null and round-trips through JSON', () {
      final withBg = base().copyWith(background: () => commander('Cult of Rakdos'));
      final restored = Player.fromJson(withBg.toJson());
      expect(restored.background?.name, 'Cult of Rakdos');
    });

    test('deserializes to null when background absent (backward compat)', () {
      final json = base().toJson()..remove('background');
      final restored = Player.fromJson(json);
      expect(restored.background, isNull);
    });

    test('copyWith can clear background explicitly', () {
      final withBg = base().copyWith(background: () => commander('Bg'));
      final cleared = withBg.copyWith(background: () => null);
      expect(cleared.background, isNull);
    });

    test('copyWith without background argument preserves it', () {
      final withBg = base().copyWith(background: () => commander('Bg'));
      final renamed = withBg.copyWith(name: 'Sara');
      expect(renamed.background?.name, 'Bg');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/player_repository && flutter test test/models/player_background_test.dart`
Expected: FAIL — `The named parameter 'background' isn't defined`.

- [ ] **Step 3: Add the field to `Player`**

In `packages/player_repository/lib/models/player.dart`, add the constructor parameter (after `this.partner,`):

```dart
    this.commander,
    this.partner,
    this.background,
```

Add the field declaration (after the `partner` field):

```dart
  /// The commander's partner card (a second *attacking* commander). Drives a
  /// separate commander-damage clock.
  final Commander? partner;

  /// A non-attacking second card (a Background enchantment). Contributes to
  /// color identity and art only — never a commander-damage clock.
  final Commander? background;
```

Add to `copyWith` parameters (after `Commander? Function()? partner,`):

```dart
    Commander? Function()? partner,
    Commander? Function()? background,
```

Add to the `copyWith` body (after the `partner:` line):

```dart
      partner: partner != null ? partner() : this.partner,
      background: background != null ? background() : this.background,
```

Add to `props` (after `partner,`):

```dart
        partner,
        background,
```

- [ ] **Step 4: Regenerate codegen**

Run: `cd packages/player_repository && dart run build_runner build --delete-conflicting-outputs`
Expected: `player.g.dart` regenerated with `background` in `_$PlayerFromJson`/`_$PlayerToJson`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd packages/player_repository && flutter test test/models/player_background_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add packages/player_repository/lib/models/player.dart \
        packages/player_repository/lib/models/player.g.dart \
        packages/player_repository/test/models/player_background_test.dart
git commit -m "feat: add non-attacking background slot to Player model"
```

---

### Task 3: Pairing auto-detection (`commanderPairingFor`)

**Files:**
- Create: `packages/player_repository/lib/models/commander_pairing.dart`
- Modify: `packages/player_repository/lib/models/models.dart` (export)
- Test: `packages/player_repository/test/models/commander_pairing_test.dart` (create)

**Interfaces:**
- Produces: `enum CommanderPairing { none, partner, background }` and
  `CommanderPairing commanderPairingFor(Commander commander)`.
  - `partner` ⇒ a second attacking commander is allowed (adds a damage clock).
  - `background` ⇒ a Background enchantment is allowed (color identity only).
  - `none` ⇒ no second card.

- [ ] **Step 1: Write the failing test**

Create `packages/player_repository/test/models/commander_pairing_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:player_repository/player_repository.dart';

void main() {
  Commander commander({
    List<String> keywords = const [],
    String oracleText = '',
    String cardType = 'Legendary Creature',
  }) =>
      Commander(
        name: 'Test',
        colors: const ['U'],
        cardType: cardType,
        imageUrl: 'https://example.com/x.jpg',
        manaCost: '{U}',
        oracleText: oracleText,
        artist: 'Artist',
        keywords: keywords,
      );

  group('commanderPairingFor', () {
    test('plain commander => none', () {
      expect(commanderPairingFor(commander()), CommanderPairing.none);
    });

    test('Partner keyword => partner', () {
      expect(
        commanderPairingFor(commander(keywords: ['Partner'])),
        CommanderPairing.partner,
      );
    });

    test('Partner with X (keyword) => partner', () {
      expect(
        commanderPairingFor(commander(keywords: ['Partner with'])),
        CommanderPairing.partner,
      );
    });

    test('Friends forever => partner', () {
      expect(
        commanderPairingFor(commander(keywords: ['Friends forever'])),
        CommanderPairing.partner,
      );
    });

    test("Doctor's companion => partner", () {
      expect(
        commanderPairingFor(commander(keywords: ["Doctor's companion"])),
        CommanderPairing.partner,
      );
    });

    test('Choose a Background (oracle text) => background', () {
      expect(
        commanderPairingFor(
          commander(oracleText: 'Choose a Background (You can have a '
              'Background as a second commander.)'),
        ),
        CommanderPairing.background,
      );
    });

    test('detection is case-insensitive', () {
      expect(
        commanderPairingFor(commander(keywords: ['PARTNER'])),
        CommanderPairing.partner,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/player_repository && flutter test test/models/commander_pairing_test.dart`
Expected: FAIL — `The function 'commanderPairingFor' isn't defined`.

- [ ] **Step 3: Implement the detection function**

Create `packages/player_repository/lib/models/commander_pairing.dart`:

```dart
import 'package:player_repository/models/commander.dart';

/// How a commander may take a second card.
enum CommanderPairing {
  /// No second card.
  none,

  /// A second *attacking* commander (Partner / Partner with / Friends
  /// forever / Doctor's companion). Adds its own commander-damage clock.
  partner,

  /// A Background enchantment. Affects color identity only — no clock.
  background,
}

const _attackingMarkers = [
  'partner',
  'friends forever',
  "doctor's companion",
];

/// Classifies how [commander] may pair with a second card, based on its
/// Scryfall keywords and oracle text. Background is checked first because a
/// background-pairing commander is never also a partner-pairing one.
CommanderPairing commanderPairingFor(Commander commander) {
  final keywords = commander.keywords.map((k) => k.toLowerCase()).toList();
  final oracle = commander.oracleText.toLowerCase();

  final isBackground = keywords.any((k) => k.contains('background')) ||
      oracle.contains('choose a background');
  if (isBackground) return CommanderPairing.background;

  final isPartner =
      keywords.any((k) => _attackingMarkers.any((m) => k.contains(m))) ||
          _attackingMarkers.any(oracle.contains);
  if (isPartner) return CommanderPairing.partner;

  return CommanderPairing.none;
}
```

- [ ] **Step 4: Export it**

In `packages/player_repository/lib/models/models.dart`, add (keep alphabetical with the existing exports):

```dart
export 'commander_pairing.dart';
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd packages/player_repository && flutter test test/models/commander_pairing_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 6: Commit**

```bash
git add packages/player_repository/lib/models/commander_pairing.dart \
        packages/player_repository/lib/models/models.dart \
        packages/player_repository/test/models/commander_pairing_test.dart
git commit -m "feat: add commanderPairingFor auto-detection"
```

---

### Task 4: Populate `keywords` in the Scryfall→Commander mapper

**Files:**
- Modify: `lib/app/utils/commander_mapper.dart:8-25`

**Interfaces:**
- Consumes: `MagicCard.keywords` (`List<String>`, from `api_client`).
- Produces: `magicCardToCommander` now copies `keywords` into the `Commander`.

Note: `MagicCard` has ~50 required fields and the project has no card fixture, so this single-field copy is verified by `flutter analyze` plus the downstream pairing tests (Task 3) rather than a dedicated fixture-heavy unit test.

- [ ] **Step 1: Add the field to the mapper**

In `lib/app/utils/commander_mapper.dart`, add `keywords` to the `Commander(...)` construction (after `toughness: card.toughness,`):

```dart
    power: card.power,
    toughness: card.toughness,
    keywords: card.keywords,
  );
```

- [ ] **Step 2: Verify it compiles cleanly**

Run: `flutter analyze lib/app/utils/commander_mapper.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/app/utils/commander_mapper.dart
git commit -m "feat: map Scryfall keywords into Commander"
```

---

### Task 5: Thread `background` through the player save path

**Files:**
- Modify: `lib/player/bloc/player_event.dart:12-26` (`UpdatePlayerInfoEvent`)
- Modify: `lib/player/bloc/player_bloc.dart:88-109` (`_onPlayerInfoUpdate`)

**Interfaces:**
- Consumes: `Player.copyWith({Commander? Function()? background})` (Task 2).
- Produces: `UpdatePlayerInfoEvent({Commander? background, ...})`; the handler writes `background` onto the player. (The UI call site that supplies `background` is updated in Plan C; until then callers omit it and it defaults to `null` — additive, backward-compatible.)

- [ ] **Step 1: Add `background` to the event**

In `lib/player/bloc/player_event.dart`, update `UpdatePlayerInfoEvent`:

```dart
class UpdatePlayerInfoEvent extends PlayerEvent {
  const UpdatePlayerInfoEvent({
    required this.playerId,
    this.playerName,
    this.commander,
    this.partner,
    this.background,
    this.firebaseId,
  });

  final Commander? commander;
  final String? playerName;
  final String playerId;
  final Commander? partner;
  final Commander? background;
  final String? firebaseId;
}
```

- [ ] **Step 2: Write the failing bloc test**

Create `test/player/player_bloc_background_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}

void main() {
  late PlayerRepository repo;

  final player = Player(
    id: 'p1',
    name: 'Sarah',
    playerNumber: 0,
    lifePoints: 40,
    color: 0xFF378ADD,
    opponents: const [],
    state: PlayerModelState.active,
  );

  final background = Commander(
    name: 'Cult of Rakdos',
    colors: const ['B', 'R'],
    cardType: 'Legendary Enchantment — Background',
    imageUrl: 'https://example.com/bg.jpg',
    manaCost: '',
    oracleText: '',
    artist: 'Artist',
  );

  setUp(() {
    repo = _MockPlayerRepository();
    when(() => repo.getPlayerById('p1')).thenReturn(player);
    when(() => repo.players).thenAnswer((_) => Stream.value([player]));
    when(() => repo.updatePlayer(any())).thenReturn(null);
  });

  blocTest<PlayerBloc, PlayerState>(
    'UpdatePlayerInfoEvent writes background onto the player',
    build: () => PlayerBloc(playerRepository: repo, playerId: 'p1'),
    act: (bloc) => bloc.add(
      UpdatePlayerInfoEvent(
        playerId: 'p1',
        playerName: 'Sarah',
        background: background,
      ),
    ),
    verify: (_) {
      final captured =
          verify(() => repo.updatePlayer(captureAny())).captured.last as Player;
      expect(captured.background?.name, 'Cult of Rakdos');
    },
  );
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/player/player_bloc_background_test.dart`
Expected: FAIL — handler does not set `background`, so `captured.background` is `null`.

- [ ] **Step 4: Update the handler**

In `lib/player/bloc/player_bloc.dart`, update `_onPlayerInfoUpdate`'s `copyWith`:

```dart
    final updatedPlayer = player.copyWith(
      commander: event.commander,
      name: event.playerName,
      partner: () => event.partner,
      background: () => event.background,
      firebaseId: () => event.firebaseId,
    );
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/player/player_bloc_background_test.dart`
Expected: PASS.

- [ ] **Step 6: Verify the whole package still analyzes & tests**

Run: `flutter analyze && cd packages/player_repository && flutter test`
Expected: `No issues found!` and all player_repository tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/player/bloc/player_event.dart \
        lib/player/bloc/player_bloc.dart \
        test/player/player_bloc_background_test.dart
git commit -m "feat: persist background through player save path"
```

---

## Self-Review

- **Spec coverage (data/accuracy portions):**
  - `Commander.keywords` for auto-detection → Task 1 + Task 4. ✓
  - `Player.background` distinct from `partner` → Task 2. ✓
  - Auto-detection rules (Partner/Friends Forever/Doctor's companion → partner; Choose a Background → background) → Task 3. ✓
  - Save path carries `background` → Task 5. ✓
  - Downstream "Background never creates a partner clock": guaranteed structurally — `background` is a separate field and the in-game tracker keys the partner clock off `player.partner`, which Background never populates. The UI that enforces "background fills `background`, not `partner`" lands in Plan C; a regression widget test is listed in Plan C's scope.
  - UI, recents/favorites, rotation removal, hero banner → Plans B and C (out of scope here).
- **Placeholder scan:** none — every step has concrete code/commands.
- **Type consistency:** `keywords` is `List<String>` everywhere; `background` uses the `Commander? Function()?` copyWith style consistent with the existing `partner`; `commanderPairingFor` returns `CommanderPairing` used consistently.
