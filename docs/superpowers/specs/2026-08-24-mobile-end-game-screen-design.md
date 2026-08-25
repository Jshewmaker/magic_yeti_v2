# Mobile End-Game Screen — Design

**Date:** 2026-08-24
**Owner:** Claude (feature owner, per delegated goal)
**Status:** Approved for implementation

## Goal

The end-of-game screen (`GameOverPage`) is built for tablets and is unusable on
phones. Make it work on phones without regressing the tablet layout.

The goal is complete when a phone user can finish a game, review and reorder the
standings, fill in both required fields, and save — with no overflow, no clipped
content, and the action buttons always reachable.

## What is broken today

`lib/life_counter/view/game_over_page.dart` is a single 964-line file whose body
is a rigid `Column`: fixed header → fixed 200pt `_WinnerHero` → `Expanded`
holding a **`Row` of two side-by-side panels** at 5:4 flex.

1. **Two-column `Row`.** On a 390pt-wide phone each panel gets ~170pt. Names,
   dropdowns, and the paired action buttons cannot fit.
2. **Nothing scrolls.** `_StandingsPanel` holds a `ReorderableListView` with
   `shrinkWrap: true` + `NeverScrollableScrollPhysics` inside a fixed-height
   box. Four 90pt rows plus margins is ~400pt, which overflows the `Expanded`.
3. **Orientation.** `four_player_game.dart:30` locks landscape and
   `GameOverPage` declares no policy, so it inherits landscape. A phone in
   landscape has ~390pt of height; header + hero alone consume ~284pt.
4. **No `SafeArea`.** Notch and home indicator clip content.
5. **`Spacer()` in `_DetailsPanel`.** Requires bounded height; throws the moment
   the panel is placed inside a scroll view.
6. **Fixed-width header reservations.** The header `Row` reserves
   `SizedBox(width: 140)` on both sides, leaving 95pt for the title on a phone.
7. **Unbounded text.** `winner.name`, player names, and commander names have no
   `maxLines`/`overflow`, so long names overflow on narrow widths.
8. **No image error handling.** `Image.network` in the hero and rows has no
   `errorBuilder`; a failed art fetch renders a broken box.

Items 5–8 affect tablets too, latently. They are fixed once, in shared widgets.

## Decisions

Four decisions were settled during brainstorming. Each is load-bearing.

| Decision | Choice | Why |
|---|---|---|
| Phone orientation | Force `portraitUp` | Landscape leaves ~390pt of height. Portrait gives ~763pt of usable height, so one scrolling column reads naturally. Matches `HomePage`. |
| Phone layout | Scroll + pinned action bar | Save/Play Again is always one tap away regardless of scroll position. |
| Reorder gesture | Drag handle only | Long-press-anywhere fights the page scroll inside a scroll view. The grip icon is already drawn on every row; it just is not wired up. |
| Tablet scope | Same look, shared hardened widgets | Tablet appearance is unchanged, but hero/standings/details/actions become shared components so fixes land on both shells. One set of components, two layout shells — the pattern `AdaptiveLayout` documents. |

## Architecture

`GameOverView` becomes an `AdaptiveLayout` over shared content widgets. Both
shells are thin — layout composition only, no duplicated content widgets.

### Phone shell

```
OrientationLock([portraitUp])
  Scaffold
    SafeArea
      Column
        GameOverHeader                    ← fixed, ~58pt
        Expanded → CustomScrollView       ← scrolls
            SliverToBoxAdapter   WinnerHero(compact: true)
            SliverToBoxAdapter   "FINAL STANDINGS" label + drag hint
            SliverReorderableList  StandingRow × n
            SliverToBoxAdapter   "MATCH DETAILS" label + both dropdowns
        GameOverActionBar                 ← pinned, ~120pt
```

`SliverReorderableList` replaces the `shrinkWrap` +
`NeverScrollableScrollPhysics` list so a drag near the screen edge auto-scrolls
the page instead of dead-ending. It requires keyed children, which the rows
already have, and it does not supply `ReorderableListView`'s Material
decoration — irrelevant here, since rows carry their own decoration and the
existing custom `proxyDecorator` is reused.

`OrientationLock` is applied on the phone branch only; tablets stay free.

### Tablet shell

Unchanged composition: `Column[ GameOverHeader, WinnerHero, Expanded(Row(5:4)[
StandingsPanel, DetailsPanel ]) ]`, with the panels' `surface` card chrome and
the `Spacer()` living in this shell rather than in the shared widgets.

### Height budget (390×844 phone)

Usable height after safe areas: 844 − 47 − 34 = **763pt**.
Header 58 + action bar 120 leaves a **~585pt viewport**.

Scroll content at 4 players: hero 204 + standings label 30 + rows 392 + gap 20 +
details label 30 + field 76 + gap 20 + field 108 ≈ **880pt**.

Content scrolls ~295pt. On a 375×667 phone the viewport is ~469pt and it scrolls
~411pt. Both are correct; scrolling is the intended behavior.

## Components

All shared between shells unless noted.

**`GameOverHeader`** — the fixed-width `Row` reservations are replaced with a
`Stack`: title centered, restore button left-aligned. Correct at any width, no
reservations. Phone renders the restore button icon-only; tablet keeps the
`RESTORE GAME` label.

**`WinnerHero`** — gains a `compact` flag.
*Tablet:* unchanged — 200pt, `Row`, boxed duration chip on the right.
*Phone:* 180pt, `Column` — trophy + WINNER, name at 30pt with `maxLines: 2` and
ellipsis, commander name, then duration as an inline clock-icon row instead of a
side chip competing for horizontal space.
Both gain an `errorBuilder` so failed art degrades to the plain gold-bordered
card.

**`StandingRow`** — the `Icons.drag_handle_rounded` icon becomes a real
`ReorderableDragStartListener`. The grip drags; everything else scrolls. Player
and commander names gain `maxLines` + ellipsis. Art gains an `errorBuilder`.

**Panel chrome** — tablet keeps both `surface` cards. Phone drops them in favor
of section labels with full-bleed rows: rows already carry their own
`surfaceRaised` background and border, so an outer card is a box-in-box costing
40pt of a 390pt screen. Rows go from ~303pt to ~343pt wide.

**Details fields** — the shared widget is `[label, dropdown, label, dropdown]`
only. The `Spacer()` moves into the tablet shell's `Column`.

**`GameOverActionBar`** — carries the "Fill out both fields to continue" hint
plus both buttons, so the reason a button is disabled sits next to it.
*Phone:* buttons **stack full-width**, Play Again (primary) above Return to
Home. Side by side gives each ~134pt of inner width while `RETURN TO HOME`
measures ~126pt — it fits only in English at default text scale and breaks at
any larger accessibility scale or longer translation.
*Tablet:* side by side, unchanged.

## Localization

One new ARB key in `lib/l10n/arb/app_en.arb`:

- `accountOwnerShort` = `"Account Owner"`

`l10n.accountOwner` is a full sentence — *"Please select the account owner from
the list to sync the game stats to their account:"* — used as a field label. At
11pt on a phone it wraps to ~3 lines. The adjacent tap-tooltip already carries
the full explanation. Phone uses the short key; **tablet keeps the existing
sentence**, so tablet appearance is unchanged.

Run `flutter gen-l10n --arb-dir="lib/l10n/arb"` after editing.

Note: `app_en.arb` contains a duplicate `gameDuration` key (lines 267 and 412).
Pre-existing, out of scope, not touched here.

## File layout

`game_over_page.dart` is 964 lines and would grow past 1,200. Split along the
CLAUDE.md `lib/<feature>/widgets/` convention:

| File | Contents |
|---|---|
| `view/game_over_page.dart` | `GameOverPage`, `GameOverView`, both `AdaptiveLayout` shells |
| `widgets/game_over/game_over_tokens.dart` | `_MC` → `GameOverTokens` (public, shared across files) |
| `widgets/game_over/game_over_header.dart` | header + restore button |
| `widgets/game_over/game_over_winner_hero.dart` | hero, both variants |
| `widgets/game_over/game_over_standings.dart` | standings label + `StandingRow` |
| `widgets/game_over/game_over_details.dart` | field label + both dropdowns |
| `widgets/game_over/game_over_actions.dart` | hint + action buttons |
| `widgets/game_over/game_over.dart` | barrel |

Each widget takes the data it renders plus callbacks; none reaches past
`GameOverBloc` for state. **No bloc changes** — `GameOverBloc` already exposes
everything both shells need (`standings`, `selectedPlayerId`, `firstPlayerId`,
`status`, `exitIntent`).

Widget keys currently asserted by tests — notably
`ValueKey('game_over_account_owner_dropdown')` — are preserved verbatim.

## Testing

`test/helpers/pump_app.dart` does not install `DeviceInfoProvider`, and
`DeviceInfoProvider.of` asserts on absence. `test/home/view/home_page_test.dart:97`
solves this with a local `buildSubject({required bool isPhone})`. Follow that
pattern; **do not** change the shared helper, which many tests depend on.

Existing `game_over_page_test.dart` pins `Size(1280, 800)` and exercises the
tablet path. It must keep passing without modification — that is the regression
gate on "tablet look unchanged."

New phone tests at `Size(390, 844)` with `isPhone: true`:

1. No overflow on a 2-player game.
2. No overflow on a 4-player game.
3. Standings rows are reachable by scrolling.
4. The action bar renders without scrolling (pinned).
5. Dragging a row's handle dispatches `UpdateStandingsEvent`.
6. A long player name ellipsizes rather than overflowing.
7. Both dropdowns render and dispatch their events.

Overflow assertions rely on the test binding failing on layout overflow, which
`flutter_test` reports as an exception — assert `tester.takeException()` is null.

## Out of scope

- Redesigning the tablet composition.
- Any change to `GameOverBloc`, game persistence, or the standings model.
- The duplicate `gameDuration` ARB key.
- Landscape phone support — phones are locked to portrait on this screen. The
  layout still scrolls and degrades gracefully if the OS overrides the lock
  (split screen, desktop windowing), but it is not a target.
