# Friend Head-to-Head Stats — Improvements

**Date:** 2026-07-17
**Status:** Approved, ready for implementation plan

## Context

The friend head-to-head stats page (`lib/friends_list/friend_stats/`) shipped in
#70. It shows a Ledger hero tile plus a 3-column grid of secondary stats for the
pods the signed-in user and one friend have played together. Three usability
problems remain:

1. **No date filter.** The home stats overview (`lib/stats_overview/`) has a
   `StatsTimeRange` dropdown (All Time / Last 12/6/3 Months / Last 30 Days) that
   filters games by `endTime`. The friend page has none — it always shows
   all-time.
2. **Tiles too far apart.** `GridView.count(crossAxisCount: 3,
   childAspectRatio: 0.85, crossAxisSpacing: 24, mainAxisSpacing: 16)` makes each
   cell taller than it is wide, so the fixed-size `StatsWidget` content floats in
   large vertical gaps (visible on wide/tablet screens).
3. **Titles aren't self-descriptive.** Each tile shows a terse title
   ("Pods Won" → `6·3·6`, "Their Go-To", "Time Alive") whose meaning only lives
   in a tooltip behind an info button.

## Goals

- Add a range filter that drives the **entire** friend page.
- Tighten the grid so tiles sit close together.
- Make each tile understandable at a glance, without opening the tooltip.

## Non-goals

- No changes to `FriendHeadToHeadCalculator` math or `FriendHeadToHead` model.
- No changes to the shared `StatsWidget` (home stats still use it unchanged).
- No column-count or max-width redesign — staying at 3 columns per the decision
  below.

## Design

### 1. Date filter drives the whole page

Reuse the existing `StatsTimeRange` enum from
`lib/stats_overview/stats_overview_bloc/stats_overview_bloc.dart` (exported via
the `stats_overview.dart` barrel) — do not duplicate it.

`FriendStatsBloc` changes:
- Retain the inputs as fields: `_allGames`, `_myId`, `_friendId`, and
  `_range` (default `StatsTimeRange.allTime`).
- `CompileFriendStats` populates `_allGames`/`_myId`/`_friendId`, then filters
  and computes.
- New event `FriendStatsRangeChanged(StatsTimeRange range)` updates `_range`,
  then filters and computes from the retained fields.
- A private `_filterGames(games, range)` mirrors the home-stats cutoff logic
  (`allTime` → unfiltered; otherwise keep games whose `endTime.isAfter(cutoff)`,
  with the same month/day cutoff arithmetic).
- Compute stays synchronous, so **no generation fence is needed** (unlike home
  stats, which awaits oracle-id resolution). The bloc's existing "computation is
  synchronous and cheap" comment still holds.
- `FriendStatsLoaded` carries the active `range` so the dropdown can reflect it.

UI (`friend_stats_page.dart`):
- A right-aligned `DropdownButton<StatsTimeRange>` at the top of the page body,
  styled like the home dropdown (`_buildDropdown` pattern). Changing it dispatches
  `FriendStatsRangeChanged`.
- Because the filtered games flow through `compute`, the header
  ("X pods together · since …"), the Ledger, and every tile all reflect the
  selected range automatically — no separate wiring.

### 2. Empty-in-range handling

Two distinct empty states:
- **No shared pods ever** (all-time `sharedPods == 0`): keep the existing
  `_EmptyState` ("Once you and X play a pod together…, tag them into their
  seat"). The dropdown may be hidden here — there is nothing to filter.
- **Shared pods exist all-time but none in the selected range**: show a lighter
  "No shared pods in this range" message **with the dropdown still visible**, so
  the user can widen the range instead of being trapped.

To distinguish these, the view needs to know whether *any* shared pods exist
independent of the current range. Simplest approach: the page keeps the dropdown
rendered whenever the state is `FriendStatsLoaded`, and swaps only the body
(tiles vs. in-range-empty message) based on `stats.sharedPods`. The all-time
"never played" case is the `sharedPods == 0` result of an `allTime` compile on
first load. Implementation detail for the plan: distinguishing "never" from
"none in range" can be done by checking whether `_range == allTime` — if the
range is all-time and there are 0 pods, it's the "never" case; any narrower range
with 0 pods is the "none in range" case.

### 3. Tighter grid

Keep `crossAxisCount: 3`. Reduce the vertical sprawl:
- Lower `childAspectRatio` from `0.85` toward a shorter cell (wider-than-tall or
  near-square — exact value tuned during implementation against the new card
  height).
- Reduce `crossAxisSpacing` and `mainAxisSpacing`.

Goal is visual: collapse the large vertical gaps while keeping three columns.

### 4. Self-descriptive card tiles

New local widget `FriendStatCard` in `friend_stats_tiles.dart` (a `Card` matching
`LedgerHeroTile`'s surface/padding style), rendering **title + value + caption**,
with the info button retained for the full explanation. The shared `StatsWidget`
is left untouched.

`buildFriendStatTiles` returns `FriendStatCard`s with these title/caption pairs
(values and sample-gates unchanged):

| Title          | Value (unchanged)                 | Caption                  |
|----------------|-----------------------------------|--------------------------|
| Pods Won       | `6·3·6`                           | You · Them · Field       |
| Their Go-To    | commander name                    | Most-played cmdr         |
| Avg Time Alive | `97% / 93%`                       | You / Them survived      |
| Final Two      | `1 of 15`                         | Last two standing        |
| The Beatdown   | dealt / taken                     | Cmdr dmg dealt / taken   |
| 21s            | landed / taken                    | Lethal 21s: you / them   |

"Field" = the rest of the table's wins (you + them + field = total shared pods).
Damage tiles (The Beatdown, 21s) remain omitted below their sample gates.

Captions must survive narrow phones at 3 columns via `AutoSizeText` shrinking
(the accepted tradeoff of keeping 3 columns).

## Testing

- **Bloc unit tests** (`friend_stats_bloc` test): `FriendStatsRangeChanged`
  filters games by `endTime` and recomputes; an all-time compile followed by a
  narrowed range emits a smaller `sharedPods`; range defaults to all-time on
  first compile.
- **Filter logic**: a game whose `endTime` is before the cutoff is excluded;
  one after is included (mirror the home-stats boundary behavior).
- **Widget smoke**: page renders the dropdown, tiles show captions, and the
  "no shared pods in this range" body appears (with the dropdown still present)
  when a narrowed range yields 0 pods.

## Files touched

- `lib/friends_list/friend_stats/friend_stats_bloc.dart` — range field, filter,
  new event.
- `lib/friends_list/friend_stats/friend_stats_event.dart` — `FriendStatsRangeChanged`.
- `lib/friends_list/friend_stats/friend_stats_state.dart` — `range` on `FriendStatsLoaded`.
- `lib/friends_list/friend_stats/view/friend_stats_page.dart` — dropdown, empty-in-range body, grid tuning.
- `lib/friends_list/friend_stats/view/friend_stats_tiles.dart` — `FriendStatCard`, captions.
- Tests under `test/friends_list/friend_stats/` (mirror existing structure).
