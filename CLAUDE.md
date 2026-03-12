# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Magic Yeti — a Flutter app for tracking Magic: The Gathering games (life totals, game timer, match history, player stats, commander decks, friends). Supports iOS, Android, Web, and Windows.

## Common Commands

### Run the app (three flavors)
```bash
flutter run --flavor development --target lib/main_development.dart
flutter run --flavor staging --target lib/main_staging.dart
flutter run --flavor production --target lib/main_production.dart
```

### Tests
```bash
flutter test                                          # all tests (root)
flutter test --coverage --test-randomize-ordering-seed random  # with coverage
flutter test test/path/to/specific_test.dart          # single test file
cd packages/<package_name> && flutter test            # package-level tests
```

### Lint
```bash
flutter analyze
```
Uses `very_good_analysis` (strict lint rules from Very Good Ventures).

### Code generation (JSON serialization)
```bash
dart run build_runner build --delete-conflicting-outputs
```
Run this after modifying any model class annotated with `@JsonSerializable`. Generated files are `*.g.dart`.

### Localization
```bash
flutter gen-l10n --arb-dir="lib/l10n/arb"
```
ARB files in `lib/l10n/arb/`. Supported locales: en, es. Access strings via `context.l10n.keyName`.

## Architecture

**Pattern**: BLoC + Repository. Each feature folder (`lib/<feature>/`) contains `bloc/`, `view/`, `widgets/` subdirectories.

**Navigation**: GoRouter (`lib/app/app_router/app_router.dart`).

**AppBloc** (`lib/app/bloc/`) manages top-level app state: authentication status, maintenance mode, force upgrades, onboarding. App states drive routing (unauthenticated → login, authenticated → home, etc.).

**GameBloc** (`lib/game/bloc/`) manages active game state: players, life totals, timer, elimination detection.

## Packages (`packages/`)

| Package | Purpose |
|---|---|
| `player_repository` | Core game logic: player management, game snapshots, elimination. Uses RxDart streams. |
| `firebase_database_repository` | Firestore/Realtime Database persistence for games and player data. |
| `user_repository` | User state streams, coordinates auth + database repos. |
| `scryfall_repository` + `scryfall_bulk_client` | MTG card data from Scryfall API and bulk assets. |
| `api_client` | Generic HTTP client wrapper. |
| `app_ui` | Shared theme, colors, fonts (Teko family), reusable widgets. |
| `form_inputs` | Form validation models using `formz`. |
| `authentication_client` + `firebase_authentication_client` | Abstract auth interface + Firebase impl (Google/Apple/Email). |
| `app_config_repository` | App config (maintenance mode, force upgrades). Has fake impl for testing. |
| `analytics_repository` | Analytics tracking. |

## Key Conventions

- Models use `@JsonSerializable(explicitToJson: true, includeIfNull: false)` with `json_serializable` codegen.
- State classes use `equatable` for value equality.
- Async data flows use `RxDart` `BehaviorSubject` streams in repositories, consumed by BLoCs.
- CI runs via GitHub Actions (`.github/workflows/main.yaml`): semantic PR checks, Flutter build, spell check.
