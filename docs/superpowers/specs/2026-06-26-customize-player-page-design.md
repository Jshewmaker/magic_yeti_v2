# Customize Player Page Redesign — Design

Date: 2026-06-26
Status: Draft for review
Area: `lib/player/view/customize_player_page.dart` and supporting widgets/bloc/models

## 1. Overview

The customize player page is the per-player setup screen reached by tapping a player's
name on the life counter. It captures **who** the player is (name, optional friend link)
and **what they're playing** (commander + optional second card). It currently renders as a
single rotated scroll with a Scryfall search-first commander picker.

This redesign reorients the screen around its primary job — **accurate tracking** — and
fixes a keyboard/orientation bug, while making the common case (a regular group replaying
known decks) fast and pleasant.

## 2. Goals & North Star

- **North star: accurate tracking.** Faithfully capture each player's commander setup so
  the in-game commander-damage and color-identity tracking are trustworthy.
- Secondary, in priority order: speed to start (minimal typing), identity/flair, and
  social/stats (friend linking).
- Constraint: the iPad is used flat on the table in its natural landscape orientation; the
  host types everyone's info or the tablet is passed around. Typing is rare (~2–3 times per
  ~2-hour session, at setup). Optimize for a smooth, occasional entry — not constant typing.

## 3. Relevant Commander (EDH) Background

- Most pods are 4-player free-for-all, 40 starting life.
- A player has one commander, or two via **Partner**, or one creature + a **Background**
  enchantment, or pairings like **Friends Forever** / **Doctor + Doctor's companion**.
- **Commander damage**: 21 combat damage from a single commander eliminates a player; each
  commander tracks its own clock. **Partners deal damage separately** (two clocks).
- A **Background is an enchantment** — it never deals combat damage (no extra clock) but it
  **does contribute to color identity**.
- Color identity is the union of the color identities of the commander(s)/background.

This produces the central accuracy rule:

| Second card type | Adds a damage clock? | Affects color identity? |
|---|---|---|
| (none) | no | no |
| Partner | **yes** | yes |
| Friends Forever | **yes** | yes |
| Doctor's companion | **yes** | yes |
| Background | **no** | **yes** |

## 4. Current State & the Accuracy Gap

- `CustomizePlayerPage` → `MultiBlocProvider(PlayerCustomizationBloc, FriendBloc)` →
  `CustomizePlayerView` (stateful). Wrapped in `RotatedBox(quarterTurns: isRotated ? 2 : 0)`.
- `PlayerCustomizationState` models the second card as a boolean `hasPartner` + a single
  `partner` `Commander?`. There is no Background concept.
- Commander selection is search-first (type a name → Scryfall → 7-wide grid). No recents,
  no favorites.
- Friend linking (PIN → `firebaseId`) sits at the top of the scroll.
- The game seeds both a `commander` and `partner` damage clock per opponent
  (`game_bloc.dart`); the in-game tracker shows the partner clock when
  `targetPlayer.partner?.imageUrl.isNotEmpty` (`commander_damage_tracker_widget.dart`).

**Gaps:**
1. **Keyboard upside-down for players 3 & 4** — the whole page is `RotatedBox`-flipped, but
   the OS soft keyboard cannot rotate. (Root cause; see decision in §5.1.)
2. **Background is indistinguishable from Partner** — a background stored in `partner` would
   render a bogus partner damage clock in-game. Accuracy violation.
3. **No reuse** — a regular group retypes the same commanders every week.

## 5. Design

### 5.1 Orientation / keyboard

Remove per-seat rotation from this screen. The page renders in natural landscape for
everyone; the host types or the iPad is passed. This eliminates the upside-down-keyboard
problem entirely (the native keyboard and the page now share one orientation).

- Remove the `RotatedBox` wrapper in `CustomizePlayerView.build`.
- Remove the `isRotated` plumbing into the page from `life_counter_widget.dart` (the life
  counter itself keeps rotating; only the pushed customize route does not).

### 5.2 Layout — two-pane player sheet (landscape)

A `Row` of two panes filling the landscape screen. No long scroll.

- **Left pane (~39% width): the player.**
  - Player color dot + name `TextField` (single line).
  - **Friend link** as a first-class element: linked state shows avatar + friend name + link
    icon and a "game syncs to their history" hint; unlinked shows a "Link to a friend"
    button that opens the existing PIN flow. Structured to become the future
    friends-list/auto-sync entry point without a redesign.
  - **Chosen commander(s)**: commander art card + an **adaptive typed second slot**
    (see §5.4) showing "Add partner" / "Add background" / filled second card / "No partner".
  - **"This game will track" preview** (accuracy payoff): plain-language summary of
    **commander-damage clock count** (1 for single/background, 2 for partner-type) and the
    **combined color-identity pips**, derived automatically from the selected cards.
  - **Save** button (existing behavior).
- **Right pane (~61% width): the picker.**
  - Segmented control: **Favorites / Recent / Search** with an **adaptive default**
    (Favorites if non-empty → else Recent if non-empty → else Search).
  - **Smart second-card banner** (§5.4) appears when the selected commander can pair.
  - **Card grid** reduced from 7 to ~4–5 columns for larger tap targets, with a **star
    toggle** on each card for favorites.

### 5.3 Reuse — recents & favorites (device-local, interim)

Add `shared_preferences` (first local-storage dependency in the project). Introduce a
`CommanderLibraryRepository` (interface + shared-preferences implementation) provided via
`RepositoryProvider`, exposing device-local **recents** and **favorites**.

- **Recents**: every commander/partner/background pick is pushed to a shared device list.
  Dedup by `oracleId` (stable across reprints/art), most-recent-first, **capped at 20**.
- **Favorites**: star toggle adds/removes a commander on a shared device list, keyed by
  `oracleId`, ordered most-recently-favorited first.
- **Scope**: a single shared device list (everyone who uses this iPad), matching
  "picked using that device." Not account-scoped.
- **Stored shape**: a slim subset sufficient to render a card and rebuild a selection —
  `oracleId`, `name`, `imageUrl`, `colors`, `colorIdentity`, `typeLine`/`cardType`. (Full
  `Commander` JSON is acceptable if simpler; keep it small.)
- **Migration path**: when the friends/auto-sync feature lands, per-friend recents/favorites
  move to the friend's Firebase profile; the repository interface stays, the Recent/Favorites
  tabs show the linked friend's lists when a friend is linked and fall back to the device
  list otherwise. No UI rework required.

### 5.4 Accuracy core — typed second card

Replace the boolean `hasPartner` + single `partner` with an explicit second-card concept.

**Data model**
- Add `Player.background` (`Commander?`) — a non-attacking second card (color identity +
  flair only). `Player.partner` (`Commander?`) is redefined to mean strictly an **attacking
  second commander** (Partner / Friends Forever / Doctor's companion).
- `PlayerCustomizationState`: replace `hasPartner`/`selectingPartner` semantics with a
  `secondCardType` enum `{ none, partner, background }` plus the existing `partner` and a new
  `background` slot, and a `selectingSecondCard` flag for the picker mode. (`partner` and
  `background` are mutually exclusive — a deck has at most one second card.)

**Auto-detection** (drives which second slot is offered, so the boolean toggle disappears)
- Detect pairing capability from the selected commander's card data. Add a `keywords`
  list to the `Commander` model (populated from Scryfall) and/or parse `oracleText`/`typeLine`:
  - oracle/keyword **"Choose a Background"** → offer a **Background** slot (search restricted
    to `type:background` enchantments) → non-attacking.
  - **"Partner with <name>"** → offer that specific partner → attacking.
  - generic **"Partner"** → offer a partner slot → attacking.
  - **"Friends forever"** → attacking partner slot.
  - **"Doctor's companion"** / Time Lord Doctor type → attacking partner slot.
- If no pairing capability is detected, the second slot stays "No partner" and no banner shows.

**Derived values**
- Damage clocks = `1 + (partner != null ? 1 : 0)`. Background never adds a clock.
- Color identity = union of `colorIdentity` across commander + partner + background.

**Downstream consistency**
- `commander_damage_tracker_widget.dart` already gates the partner clock on
  `targetPlayer.partner` — keeping Background out of `partner` is sufficient to avoid a bogus
  clock. Verify during implementation that nothing else infers a second attacker from
  `background`.
- `CommanderHeroBanner` shows a two-art split for a second card — extend it to split for
  **either** `partner` or `background`.
- `Player` serialization (`toJson`/`fromJson`, `copyWith`, `props`) and any game snapshot /
  Firebase persistence must include `background`. Existing saved games without the field
  deserialize as `background == null` (backward compatible).

## 6. Components / Architecture

- `CustomizePlayerView` — restructured from `CustomScrollView` to a two-pane `Row`. Holds
  the name/search controllers and focus node as today.
- New widgets (replacing/refactoring existing ones under `lib/player/view/widgets/`):
  - `PlayerIdentityPanel` (left): name field + friend link + chosen commander(s) + tracking
    preview + save. Absorbs the identity parts of today's `_FriendSection`/`PlayerNameRow`.
  - `TrackingPreview`: damage-clock count + color-identity pips from state.
  - `CommanderPickerPanel` (right): Favorites/Recent/Search segmented control, search bar
    (reuses `CommanderSearchBar`), filters, smart second-card banner, grid.
  - `CommanderGrid`: ~4–5-wide grid with `CommanderCard` (art + name + star toggle). Evolves
    `CommanderCardGrid`/`_CardGridItem`.
  - `SecondCardSlot` / banner: adaptive partner-vs-background affordance (replaces
    `CommanderSlotSelector` and the `FilterChip` "Has Partner").
- `PlayerCustomizationBloc`: new/changed events — `SelectSecondCardType`,
  `UpdateBackground`, `ToggleFavorite`, `RecentsRequested`/`FavoritesRequested` (or load on
  init), background search mode for `CardListRequested`. Remove `hasPartner` boolean.
- `CommanderLibraryRepository` (new): `getRecents()`, `addRecent(commander)`,
  `getFavorites()`, `toggleFavorite(commander)`, `isFavorite(oracleId)` — shared-preferences
  backed, interface allows a future Firebase-backed impl.

## 7. Data Flow

1. Page opens → bloc loads device recents + favorites → picker shows the adaptive default tab.
2. User taps a commander (from any tab or search) → bloc sets `commander`, runs pairing
   auto-detection, updates the smart banner, recomputes the tracking preview, and records the
   pick into recents.
3. If the commander can pair and the user adds a second card → picker enters
   `selectingSecondCard` mode (partner search = creatures; background search = backgrounds) →
   selection fills `partner` or `background` accordingly, recomputes clocks/colors.
4. Star toggle → `toggleFavorite` updates the device favorites list.
5. Save → `UpdatePlayerInfoEvent` writes name, commander, partner, **background**, and
   `firebaseId` (from friend link / account ownership) to the `Player`.

## 8. Error Handling

- Scryfall search failure / empty results: existing failure + "no commanders" states,
  reused in the picker.
- `shared_preferences` read/write failure or corrupt/legacy JSON: treat as empty list, log,
  and continue (recents/favorites are non-critical). Never block setup on storage errors.
- Auto-detection uncertainty: if pairing capability can't be determined, default to **no**
  second slot (safer for clock accuracy) rather than offering a possibly-wrong one.

## 9. Testing

- `CommanderLibraryRepository`: recents dedup-by-`oracleId`, most-recent-first ordering, cap
  at 20; favorites toggle/order; graceful handling of corrupt/legacy stored JSON.
- `PlayerCustomizationBloc`: auto-detection maps each card type to the correct second slot
  (partner vs background vs none); selecting a Background sets `background` and leaves
  `partner` null; clock count and color-identity union are correct.
- Widget: `TrackingPreview` shows 1 clock for single/background and 2 for partner-type;
  `CommanderHeroBanner` splits art for both partner and background.
- Regression: a Background never produces a partner damage clock in the in-game tracker.
- `Player` JSON round-trips with and without `background` (backward compatibility).

## 10. Out of Scope (now) / Future

- Friends list + auto-sync of games to each player's history (planned; this design keeps the
  friend-link first-class and the library repository swappable to support it).
- Per-friend recents/favorites in Firebase (layered on later via the repository interface).
- Companion (sideboard) mechanic — not a commander-damage source; not modeled now.
- Deck import (Moxfield/Archidekt), poison/energy counters, alternate starting life — not
  part of this screen.

## 11. Risks / Integration Points to Verify During Implementation

- Adding `Player.background` touches model serialization, `copyWith`, `props`, game
  snapshot, and Firebase persistence — confirm all paths and backward compatibility.
- Confirm no code path treats `background` as a second attacker (commander-damage setup,
  stats, hero banner logic).
- Adding `keywords` to `Commander` requires mapping from the Scryfall response
  (`commander_mapper.dart` / scryfall repository) — verify the field is populated.
- Restricting search to backgrounds (`type:background`) needs a search-mode parameter on the
  existing search event/repository call.
