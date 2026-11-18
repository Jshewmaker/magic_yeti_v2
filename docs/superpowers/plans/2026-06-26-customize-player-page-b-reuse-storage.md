# Customize Player Page — Plan B: Reuse Storage (Recents & Favorites)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist, on the device, the commanders picked and favorited on this iPad, so the redesigned picker can show recents and favorites before anyone searches.

**Architecture:** Add `shared_preferences`. Define a `CommanderLibraryRepository` interface and a `SharedPreferencesCommanderLibraryRepository` implementation storing two JSON lists of `Commander` (recents, capped at 20 and deduped by identity; favorites, toggled). Provide it app-wide via `RepositoryProvider`. No UI yet — Plan C consumes it.

**Tech Stack:** Dart, Flutter, `shared_preferences`, `dart:convert`, `flutter_test`, `player_repository` (`Commander`).

**Depends on:** Plan A (uses `Commander`; benefits from `keywords` but does not require it).

## Global Constraints

- SDK floor: `>=3.8.0 <4.0.0`.
- Lints: `very_good_analysis` ^10.1.0; `flutter analyze` must be clean.
- Recents are device-scoped and shared (everyone who uses this iPad), capped at **20**, most-recent-first, deduped by `oracleId` (falling back to `name` when `oracleId` is null).
- Storage failures (corrupt/legacy JSON, plugin error) must degrade to an empty list — never throw into the UI.
- Tests use `SharedPreferences.setMockInitialValues({})` and require `TestWidgetsFlutterBinding.ensureInitialized()`.

---

### Task 1: Add dependency and define the repository interface

**Files:**
- Modify: `pubspec.yaml` (dependencies)
- Create: `lib/commander_library/commander_library_repository.dart`

**Interfaces:**
- Produces:
  ```dart
  abstract interface class CommanderLibraryRepository {
    Future<List<Commander>> getRecents();
    Future<void> addRecent(Commander commander);
    Future<List<Commander>> getFavorites();
    Future<bool> toggleFavorite(Commander commander); // returns new isFavorite
    Future<bool> isFavorite(Commander commander);
  }
  ```

- [ ] **Step 1: Add `shared_preferences`**

In `pubspec.yaml`, under `dependencies:` (alphabetical, after `scryfall_repository`):

```yaml
  scryfall_repository:
    path: packages/scryfall_repository
  shared_preferences: ^2.3.2
```

- [ ] **Step 2: Fetch packages**

Run: `flutter pub get`
Expected: resolves with `shared_preferences` added.

- [ ] **Step 3: Define the interface**

Create `lib/commander_library/commander_library_repository.dart`:

```dart
import 'package:player_repository/player_repository.dart';

/// Stores commanders picked and favorited on this device, so the player
/// customization picker can offer reuse before any search.
///
/// Device-scoped and shared across everyone who uses this device. When the
/// future friends/auto-sync feature lands, a Firebase-backed implementation can
/// replace or augment this one behind the same interface.
abstract interface class CommanderLibraryRepository {
  /// Most-recently-picked commanders first (max 20).
  Future<List<Commander>> getRecents();

  /// Records [commander] as the most recent pick (dedup + cap applied).
  Future<void> addRecent(Commander commander);

  /// Favorited commanders, most-recently-favorited first.
  Future<List<Commander>> getFavorites();

  /// Adds or removes [commander] from favorites. Returns the resulting
  /// favorite state (`true` if now a favorite).
  Future<bool> toggleFavorite(Commander commander);

  /// Whether [commander] is currently a favorite.
  Future<bool> isFavorite(Commander commander);
}
```

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/commander_library/commander_library_repository.dart
git commit -m "feat: add shared_preferences and CommanderLibraryRepository interface"
```

---

### Task 2: Implement recents (dedup + cap 20)

**Files:**
- Create: `lib/commander_library/shared_preferences_commander_library_repository.dart`
- Test: `test/commander_library/commander_library_repository_test.dart` (create)

**Interfaces:**
- Consumes: `CommanderLibraryRepository` (Task 1), `Commander.toJson()`/`fromJson` (`player_repository`).
- Produces: `SharedPreferencesCommanderLibraryRepository(SharedPreferences prefs)` implementing `getRecents`/`addRecent`. Storage keys: `'cmdr_lib_recents'`, `'cmdr_lib_favorites'`.

- [ ] **Step 1: Write the failing test**

Create `test/commander_library/commander_library_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/commander_library/shared_preferences_commander_library_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Commander commander(String name, {String? oracleId}) => Commander(
      oracleId: oracleId,
      name: name,
      colors: const ['U'],
      cardType: 'Legendary Creature',
      imageUrl: 'https://example.com/$name.jpg',
      manaCost: '{U}',
      oracleText: '',
      artist: 'Artist',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesCommanderLibraryRepository repo;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SharedPreferencesCommanderLibraryRepository(prefs);
  }

  setUp(build);

  group('recents', () {
    test('starts empty', () async {
      expect(await repo.getRecents(), isEmpty);
    });

    test('addRecent puts newest first', () async {
      await repo.addRecent(commander('Atraxa', oracleId: 'a'));
      await repo.addRecent(commander('Yuriko', oracleId: 'y'));
      final recents = await repo.getRecents();
      expect(recents.map((c) => c.name), ['Yuriko', 'Atraxa']);
    });

    test('re-adding moves to front without duplicating (dedup by oracleId)',
        () async {
      await repo.addRecent(commander('Atraxa', oracleId: 'a'));
      await repo.addRecent(commander('Yuriko', oracleId: 'y'));
      await repo.addRecent(commander('Atraxa', oracleId: 'a'));
      final recents = await repo.getRecents();
      expect(recents.map((c) => c.name), ['Atraxa', 'Yuriko']);
    });

    test('caps at 20', () async {
      for (var i = 0; i < 25; i++) {
        await repo.addRecent(commander('C$i', oracleId: '$i'));
      }
      final recents = await repo.getRecents();
      expect(recents.length, 20);
      expect(recents.first.name, 'C24');
      expect(recents.last.name, 'C5');
    });

    test('corrupt stored JSON degrades to empty', () async {
      SharedPreferences.setMockInitialValues({'cmdr_lib_recents': 'not json'});
      final prefs = await SharedPreferences.getInstance();
      final r = SharedPreferencesCommanderLibraryRepository(prefs);
      expect(await r.getRecents(), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/commander_library/commander_library_repository_test.dart`
Expected: FAIL — `SharedPreferencesCommanderLibraryRepository` not found.

- [ ] **Step 3: Implement recents**

Create `lib/commander_library/shared_preferences_commander_library_repository.dart`:

```dart
import 'dart:convert';

import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local [CommanderLibraryRepository] backed by [SharedPreferences].
class SharedPreferencesCommanderLibraryRepository
    implements CommanderLibraryRepository {
  SharedPreferencesCommanderLibraryRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _recentsKey = 'cmdr_lib_recents';
  static const _favoritesKey = 'cmdr_lib_favorites';
  static const _maxRecents = 20;

  String _identity(Commander c) => c.oracleId ?? c.name;

  List<Commander> _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Commander.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> _write(String key, List<Commander> commanders) async {
    final encoded =
        jsonEncode(commanders.map((c) => c.toJson()).toList());
    await _prefs.setString(key, encoded);
  }

  @override
  Future<List<Commander>> getRecents() async => _read(_recentsKey);

  @override
  Future<void> addRecent(Commander commander) async {
    final recents = _read(_recentsKey)
      ..removeWhere((c) => _identity(c) == _identity(commander));
    recents.insert(0, commander);
    if (recents.length > _maxRecents) {
      recents.removeRange(_maxRecents, recents.length);
    }
    await _write(_recentsKey, recents);
  }

  @override
  Future<List<Commander>> getFavorites() async => _read(_favoritesKey);

  @override
  Future<bool> toggleFavorite(Commander commander) async {
    final favorites = _read(_favoritesKey);
    final existing =
        favorites.indexWhere((c) => _identity(c) == _identity(commander));
    if (existing >= 0) {
      favorites.removeAt(existing);
      await _write(_favoritesKey, favorites);
      return false;
    }
    favorites.insert(0, commander);
    await _write(_favoritesKey, favorites);
    return true;
  }

  @override
  Future<bool> isFavorite(Commander commander) async {
    return _read(_favoritesKey)
        .any((c) => _identity(c) == _identity(commander));
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/commander_library/commander_library_repository_test.dart`
Expected: PASS (recents group, 5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/commander_library/shared_preferences_commander_library_repository.dart \
        test/commander_library/commander_library_repository_test.dart
git commit -m "feat: implement device-local recent commanders storage"
```

---

### Task 3: Implement favorites (toggle + isFavorite)

**Files:**
- Test: `test/commander_library/commander_library_repository_test.dart` (extend)

(The favorites code already landed in Task 3's implementation file; this task adds its tests — they were written alongside but are split out so favorites can be reviewed independently.)

**Interfaces:**
- Consumes: `toggleFavorite`, `isFavorite`, `getFavorites` from Task 2's class.

- [ ] **Step 1: Add the failing favorites tests**

Append a new group inside `main()` in
`test/commander_library/commander_library_repository_test.dart` (after the `recents` group):

```dart
  group('favorites', () {
    test('toggle adds then removes, reporting new state', () async {
      final atraxa = commander('Atraxa', oracleId: 'a');
      expect(await repo.isFavorite(atraxa), isFalse);

      expect(await repo.toggleFavorite(atraxa), isTrue);
      expect(await repo.isFavorite(atraxa), isTrue);
      expect((await repo.getFavorites()).single.name, 'Atraxa');

      expect(await repo.toggleFavorite(atraxa), isFalse);
      expect(await repo.isFavorite(atraxa), isFalse);
      expect(await repo.getFavorites(), isEmpty);
    });

    test('favorites are independent of recents', () async {
      await repo.addRecent(commander('Yuriko', oracleId: 'y'));
      await repo.toggleFavorite(commander('Atraxa', oracleId: 'a'));
      expect((await repo.getRecents()).single.name, 'Yuriko');
      expect((await repo.getFavorites()).single.name, 'Atraxa');
    });
  });
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `flutter test test/commander_library/commander_library_repository_test.dart`
Expected: PASS (recents + favorites groups).

- [ ] **Step 3: Commit**

```bash
git add test/commander_library/commander_library_repository_test.dart
git commit -m "test: cover commander favorites storage"
```

---

### Task 4: Provide the repository app-wide

**Files:**
- Modify: `lib/app/view/app.dart` (constructor fields + `RepositoryProvider`)
- Modify: `lib/main_development.dart`
- Modify: `lib/main_staging.dart`
- Modify: `lib/main_production.dart`

**Interfaces:**
- Produces: `CommanderLibraryRepository` available via `context.read<CommanderLibraryRepository>()` (consumed in Plan C).

- [ ] **Step 1: Accept and provide the repository in `App`**

In `lib/app/view/app.dart`, add the import:

```dart
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
```

Add a constructor parameter (after `required PlayerRepository playerRepository,`):

```dart
    required PlayerRepository playerRepository,
    required CommanderLibraryRepository commanderLibraryRepository,
```

Add the initializer (after `_playerRepository = playerRepository,`):

```dart
        _playerRepository = playerRepository,
        _commanderLibraryRepository = commanderLibraryRepository,
```

Add the field (after `final PlayerRepository _playerRepository;`):

```dart
  final PlayerRepository _playerRepository;
  final CommanderLibraryRepository _commanderLibraryRepository;
```

Add the provider (after `RepositoryProvider.value(value: _playerRepository),`):

```dart
        RepositoryProvider.value(value: _playerRepository),
        RepositoryProvider.value(value: _commanderLibraryRepository),
```

- [ ] **Step 2: Construct and pass it in each entrypoint**

In **each** of `lib/main_development.dart`, `lib/main_staging.dart`,
`lib/main_production.dart`, add the imports:

```dart
import 'package:magic_yeti/commander_library/shared_preferences_commander_library_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

Inside the `bootstrap(...)` async builder, construct it (after the
`scryfallRepository` line):

```dart
      final scryfallRepository = ScryfallRepository();
      final commanderLibraryRepository =
          SharedPreferencesCommanderLibraryRepository(
        await SharedPreferences.getInstance(),
      );
```

Add it to the `App(...)` call:

```dart
        playerRepository: playerRepository,
        commanderLibraryRepository: commanderLibraryRepository,
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Build a flavor to confirm wiring**

Run: `flutter build apk --flavor development --target lib/main_development.dart --debug` (or `flutter run` on a device/simulator and confirm the app launches).
Expected: build succeeds; app starts.

- [ ] **Step 5: Commit**

```bash
git add lib/app/view/app.dart lib/main_development.dart lib/main_staging.dart lib/main_production.dart
git commit -m "feat: provide CommanderLibraryRepository app-wide"
```

---

## Self-Review

- **Spec coverage (reuse storage):**
  - `shared_preferences` added → Task 1. ✓
  - `CommanderLibraryRepository` interface + shared-prefs impl → Tasks 1–3. ✓
  - Shared device list, dedup by `oracleId`, cap 20, most-recent-first → Task 2. ✓
  - Favorites toggle/order → Tasks 2–3. ✓
  - Graceful degradation on corrupt/legacy JSON → Task 2 (`corrupt stored JSON` test). ✓
  - Provided via `RepositoryProvider` → Task 4. ✓
  - Future per-friend Firebase impl behind same interface → enabled by the `abstract interface class` (no code now). ✓
- **Placeholder scan:** none.
- **Type consistency:** storage keys `cmdr_lib_recents` / `cmdr_lib_favorites` used consistently; `toggleFavorite` returns `bool` (new favorite state) everywhere; identity = `oracleId ?? name` in both repo and tests.
