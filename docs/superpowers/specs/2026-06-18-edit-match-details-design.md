# Edit a Finished Match (Match Details)

## Overview

Add the ability to **edit a finished match** from the Match Details screen. After a
game is over, the user can correct what was recorded for each player:

- **Player name**
- **Commander** (primary)
- **Partner commander** (the second commander, for partner pairs)

Editing happens **inline** on the existing Match Details screen via an edit-mode toggle.
A single Save persists all changes to the current user's saved copy of the match; the
screen then returns to its read-only state.

Out of scope for this iteration: winner, placements, who went first, duration, room id,
and date are **not** editable.

## Current State (what exists today)

- `lib/match_details/` renders a **read-only** screen. `MatchDetailsPage` →
  `MatchDetailsView` → `_PhoneMatchDetailsView` / `_TabletMatchDetailsView`, each showing
  `MatchWinnerWidget`, `MatchStandingsWidget`, `MatchMetadataWidget`.
- The screen reads the `GameModel` from `MatchHistoryBloc.state.games` (watched) by
  `gameId`. `MatchHistoryBloc` streams `databaseRepository.getGames(userId)` in real time,
  so any persisted write reflects back automatically.
- `MatchDetailsBloc` already performs match mutations and persists them:
  `UpdatePlayerOwnership` calls `databaseRepository.updateGameStats(game, playerId)`, and
  `DeleteMatchEvent` calls `deleteGame`. **The write-path needed for editing already
  exists.**
- Models are immutable with `copyWith`: `GameModel.copyWith(players:)`,
  `Player.copyWith(name:, commander:, partner:)`, `Commander`.
- A commander search/select UX already exists in the live-game flow
  (`lib/player/view/`): `CommanderSearchBar` + `CommanderCardGrid`, driven by
  `PlayerCustomizationBloc`, backed by `ScryfallRepository.getCardFullText`. Its *save*
  path writes to the live `PlayerRepository`, not to a persisted match — so we reuse the
  *search UX*, not the save path.

## Change 1: Inline Edit Mode

### Solution

Add an **Edit (pencil)** action to the Match Details app bar, beside Delete. Tapping it
enters **edit mode**; the Winner and Standings cards swap their static name/commander
displays for editable controls. The Metadata card stays read-only.

### Behavior

- **App bar:**
  - Read-only: shows the pencil (Edit) action and the existing Delete action.
  - Editing: shows **Save (✓)** and **Cancel (✕)**; the Delete action is hidden.
- **Player name** → inline `TextField`, pre-filled with the current name. All names are
  editable (see Scope).
- **Commander** → the avatar/name becomes tappable; tapping opens the **commander picker**
  (Change 2) and applies the chosen `Commander` to that player's draft.
- **Partner slot** → each player row shows:
  - If a partner exists: the partner commander (tap to change) with a small **✕** to
    remove it.
  - If no partner: an **"Add partner"** affordance that opens the picker in partner mode.
- **Save** persists all changes at once, exits edit mode, and shows a confirmation
  SnackBar.
- **Cancel** discards the draft and exits edit mode.

### Files Changed

- `lib/match_details/view/match_details_page.dart`:
  - Add `MatchEditCubit` to the `BlocProvider` set in `MatchDetailsPage.build` (alongside
    the existing `MatchDetailsBloc`).
  - App-bar actions become edit-aware (pencil ↔ ✓/✕, hide Delete while editing), driven
    by `MatchEditCubit` state. Applies to both the phone and tablet app bars.
  - `MatchWinnerWidget` and `MatchStandingsWidget` gain editable variants: a name
    `TextField`, a tappable commander avatar, and a partner slot when `isEditing` is true.
    Read-only rendering is unchanged when not editing.
  - The view becomes `StatefulWidget` to own the per-player name `TextEditingController`s
    and their lifecycle.

## Change 2: Commander Picker (reusable component)

### Solution

A **full-screen modal** that searches Scryfall and returns the selected `Commander`. The
7-column card grid needs real space, matching the existing customize-player layout. The
same picker serves both the primary commander and the partner (via a `selectingPartner` /
title parameter).

### Behavior

- Presents a search field + results grid (reusing the existing `CommanderSearchBar` and
  `CommanderCardGrid` look-and-feel).
- Tapping a card resolves to a `Commander` and closes the modal, returning it to the
  caller (e.g. `Future<Commander?>`).
- Dismissing without a selection returns `null` (no change).

### Implementation

- New lightweight **`CommanderPickerCubit`** that owns only Scryfall search + the
  "legendary" filter (the same filter `PlayerCustomizationBloc._cardListRequested` uses).
  This avoids pulling `PlayerCustomizationBloc`'s friend/PIN/account-ownership concerns
  into the match-edit context.
- **Extract the `MagicCard → Commander` mapping** currently inlined in
  `CommanderCardGrid._onCardTapped` into a single shared helper, used by both the live
  customize flow and the new picker. This removes duplication and keeps the two flows
  consistent.

### Files Changed

- `lib/match_details/widgets/commander_picker.dart` — **new** (modal widget +
  `showCommanderPicker(...)` entry point).
- `lib/match_details/bloc/commander_picker_cubit.dart` (+ state) — **new**.
- Shared `MagicCard → Commander` mapping helper — **new** top-level function in a neutral
  location (used by both `lib/player/` and `lib/match_details/`).
  `CommanderCardGrid._onCardTapped` is updated to call it instead of building the
  `Commander` inline.

## Change 3: Edit State & Persistence

### Solution

A new **`MatchEditCubit`** owns the edit session and the draft. The read-only
`MatchDetailsBloc` (delete + ownership) is left untouched.

### Behavior

- Seeded from the match's `GameModel`. Holds `isEditing` and a **draft** `List<Player>`
  as the single source of truth for in-progress edits.
- Methods:
  - `startEditing()` — copy current players into the draft, set `isEditing = true`.
  - `cancel()` — discard the draft, set `isEditing = false`.
  - `updateName(playerId, name)`
  - `setCommander(playerId, commander)`
  - `setPartner(playerId, commander?)` — `null` removes the partner.
  - `save()` — build `game.copyWith(players: draft)`, call
    `databaseRepository.updateGameStats(game: updatedGame, playerId: currentUserId)`, emit
    success.
- States: `viewing` / `editing(draft)` / `saving` / `success` / `error(message)`.
- After a successful save, the `MatchHistoryBloc` stream emits the updated game and the
  screen re-renders read-only — **no manual refresh needed**.
- Name `TextField`s are backed by `TextEditingController`s in the view and write back to
  the cubit (so the cubit's draft stays authoritative).

### Persistence Scope

- Writes only the **current user's copy** of the match
  (`updateGameStats(game, currentUserId)`), mirroring the existing `UpdatePlayerOwnership`
  and `deleteGame` behavior.
- When a game ends, `syncGameToPlayers` copies it into every signed-in participant's
  `users/{uid}/matches` subcollection. An edit here does **not** propagate to other
  participants' copies. This is a **known limitation**, documented; fan-out to other
  participants is a possible follow-up.
- Because `stats_overview` derives from the games list, correcting a misrecorded commander
  or name **automatically corrects the affected stats** — a deliberate benefit.

### Files Changed

- `lib/match_details/bloc/match_edit_cubit.dart` (+ state) — **new**.
- `lib/match_details/match_details.dart` — export the new cubit/picker as needed.

## Data Model

No model changes. `GameModel`, `Player`, and `Commander` already support everything via
their existing fields and `copyWith`.

## Scope

- **Editable:** each player's name, commander, and partner commander.
- **All player names are editable**, including players linked to an account (you / a
  friend). The live setup flow locks a friend-linked name to keep it synced to that
  friend's username, but here the stored name is a historical snapshot of this match, and
  the edit only affects this match's saved copy. (Decision: do not lock linked names.)
- **Not editable:** winner, placement, who went first, duration, room id, date.
- Any user viewing the match in their own history may edit their copy (consistent with the
  existing delete behavior).

## Localization

Add ARB strings (en + es) in `lib/l10n/arb/` for new UI: edit / save / cancel actions,
"Add partner", remove-partner, picker title/hint, and the save-confirmation SnackBar.
Access via `context.l10n.*`.

## Testing

- **`MatchEditCubit`:** start/cancel/mutate/save flows; save-error path; draft isolation
  (cancel restores the original; the live game list is unaffected until save).
- **`CommanderPickerCubit`:** search success / empty / failure; legendary filter applied.
- **Widget tests (`test/match_details/`):**
  - App-bar toggles between pencil and ✓/✕; Delete hidden while editing.
  - Editing a name updates the draft.
  - Tapping a commander opens the picker and applies the returned selection.
  - Adding and removing a partner.
  - Save persists via a mocked `FirebaseDatabaseRepository` and exits edit mode.
  - Cancel discards changes.
- Follow `very_good_analysis`; mock repositories with the existing `mocktail` patterns.

## Files Touched (summary)

| File | Change |
|---|---|
| `lib/match_details/view/match_details_page.dart` | Edit-aware app bar; editable Winner/Standings; partner slot; provide `MatchEditCubit`; Stateful for controllers |
| `lib/match_details/bloc/match_edit_cubit.dart` (+ state) | **New** — edit session, draft, save |
| `lib/match_details/widgets/commander_picker.dart` | **New** — full-screen picker modal |
| `lib/match_details/bloc/commander_picker_cubit.dart` (+ state) | **New** — Scryfall search + legendary filter |
| `MagicCard → Commander` mapping helper | **New** — extracted, shared with `CommanderCardGrid` |
| `lib/match_details/match_details.dart` | Exports |
| `lib/l10n/arb/app_*.arb` | New strings (en + es) |
| `test/match_details/...` | Cubit + widget tests |
