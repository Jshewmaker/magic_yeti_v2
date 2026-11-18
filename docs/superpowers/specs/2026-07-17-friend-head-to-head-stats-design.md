# Friend Head-to-Head Stats — Design

**Date:** 2026-07-17
**Owner:** Claude (feature owner, per delegated goal)
**Status:** Approved for implementation

## Goal

From the friends list, tap a friend and see fun, format-authentic Commander stats
about the pods the two of you have played together. Plus a way to retro-tag a
friend into games played before the friends list existed.

The goal is complete when a user can select a friend and see head-to-head stats.

## Key insight (from the commander-expert consult)

At the real sample size — most friend pairs will have **3–15 shared pods, ever** —
win-rate percentages are statistically meaningless (±13 pts of noise over 11 pods)
and get misread against a 50% mental baseline that does not apply to a 4-player
pod (baseline is 25%). So:

- **The screen is built on counts, not percentages.** Counts are honest at n=1.
- **"Who finished ahead" is the headline**, not "who won." Wins are a 25% event
  (~3 data points over 11 pods); *finishing ahead* is defined in **every** shared
  pod with a true 50% baseline — 4× the signal from identical data, and it
  sidesteps pod-size normalization entirely.

Full consult (with the ranked stat list, cuts, and a future-work wishlist) is in
`docs/superpowers/notes/2026-07-17-commander-expert-friend-stats.md`.

## Architecture — no backend changes

`onGameCreated` already fans every finished game into each participant's
`users/{uid}/matches`. So the signed-in user's **own** match history already
contains every shared pod, with all seats, commanders, placements, death times,
and the full directed commander-damage graph.

> **Shared pods with friend F** = games in *my own* history where one seat's
> `firebaseId == myId` **and** a *different* seat's `firebaseId == F`.

No Cloud Function, no `firestore.rules` change, no composite index. The friend's
owner-only history is never read.

### Components

1. **`FriendHeadToHead`** (model) — the computed result object.
2. **`FriendHeadToHeadCalculator`** (pure) — `compute(games, myId, friendId)
   → FriendHeadToHead`. Fully unit-testable, no I/O. The existing global stats
   compute inline in `StatsOverviewBloc` with no calculator (a smell); this one
   is done right so the correctness rules below are test-locked.
3. **`FriendStatsBloc`** — thin wrapper. Event `CompileFriendStats({myId,
   friendId, games})`; states initial/loading/loaded/failure. No time-range
   filter (would empty small samples). No generation-fence needed — compute is
   synchronous and cheap.
4. **`FriendStatsPage` / `FriendStatsView`** — provides the bloc, feeds games in
   from the app-wide `MatchHistoryBloc` via `BlocListener` (same pattern as
   `StatsOverviewWidget`). Header + hero Ledger tile + `StatsGrid`.
5. **Backfill** — generalize `MatchDetailsBloc`'s `UpdatePlayerOwnership` into
   `AssignSeatIdentity`.

### Correctness rules (verified against the code; each has a reason)

- **No `_findPlayerInGame` fallback.** That helper falls back to `players.first`;
  on a friend screen it would attribute an untagged seat to the friend and
  fabricate a rivalry. Require both `firebaseId`s explicitly, on distinct seats.
- **Order by `timeOfDeath`, not `placement`.** `placement` is recomputed as
  `totalPlayers − eliminated` and player revives can make two seats share a
  placement (`player_repository.dart:146,156`). `timeOfDeath` is strictly ordered
  epoch millis; the winner gets one at game end (`player_repository.dart:66`).
- **Detect wins via `GameModel.winnerId`** (holds the winning `Player.id`).
- **Read `placement`/`timeOfDeath` defensively.** Both are throwing getters
  (`_value!`, guarded on `isEliminated`). Read through a try/catch accessor;
  drop any shared-game candidate whose two seats don't both yield a
  `timeOfDeath`. One malformed legacy doc must not throw the whole screen.
- **Per-clock lethality, per-player volume.** A 21-damage kill is
  `damages.any(d.amount >= 21)` on a *single* clock (Partner clocks don't stack).
  Total damage *volume* sums `commander` + `partner`. `opponents` is looked up by
  the dealing seat's per-game `id`; skip the seeded self-entry implicitly by
  always looking up the *other* seat's id.
- **Survival fraction normalizes against wall-clock**, `(timeOfDeath −
  startTime) / (endTime − startTime)`, clamped [0,1] — **not** `durationInSeconds`,
  which is the pausable game timer and can undercount.

## The stats (v1)

Hero tile on top; the rest in a 3-column `StatsGrid`. Gating uses the existing
`Need N+ games` copy; damage tiles hide entirely rather than show `0–0`.

| Tile | Value | Min to show |
|---|---|---|
| **The Ledger** *(hero)* | Pods you finished ahead vs behind — `7–4` | 3 pods |
| **Pods Won** | `You 3 · Them 2 · Table 6`, subtitle "even split ≈ 2.8 each" | 3 pods |
| **Time Alive** | Mean survival fraction, you vs them (`71% · 54%`) | 5 pods |
| **Final Two** | Times you two were the last standing (`4 of 11`) | 5 pods |
| **The Beatdown** | Commander damage traded (`Dealt 63 · Taken 19`) | total flow ≥ 21 |
| **21s** | 21-damage commander kills each way | ≥ 1 occurrence |
| **Their Go-To** | Their most-played commander at your table (+ art) | 3 pods |
| **Pods Together** | Shared pod count + first date | 1 pod |

**Cut from v1** (per consult): Focus Fire (targeting bias — too sparse/needs an
explained baseline) and Pod Length (a property of the pod, not the pair).

**Empty state** (0 shared pods): explain that you can tag this friend into past
games from a match's detail page — closing the loop with backfill discovery.

## Backfill — per-game seat assignment (user's chosen approach)

Generalize the match-details seat control. Today each non-owned seat shows a
"claim as me" button; tapping assigns *my* id to that seat and strips it from
others, writing to my own history copy via `updateGameStats`.

Generalize to an assignment sheet — **Me / <each friend> / Unassign** — backed by
a new event:

```dart
AssignSeatIdentity({
  required GameModel game,
  required Player seat,
  required String? assignedFirebaseId, // identity for the seat (null = unassign)
  required String ownerUserId,         // whose history copy we write to (= me)
})
```

Bloc logic (subsumes the old event): set `seat.firebaseId = assignedFirebaseId`;
if non-null, strip that same id from any *other* seat (one seat per identity);
write `updateGameStats(game: updated, playerId: ownerUserId)`. `ownerUserId` is
**always the current user** — tagging a friend edits *my* private copy only; the
friend sees nothing, so no consent is required. The friends offered come from
`watchFriends(myId)`.

While here, fix the pre-existing bug where `MatchStandingsWidget` is passed
`currentUserFirebaseId: game.hostId` — the "You" marker should key off the
signed-in user, and friend-tagged seats should render distinctly.

## Entry point & routing

- `FriendCard` gains an optional `onTap`; the friends list wires it to push
  `FriendStatsPage`.
- Route `/friend_stats_page/:friendId` (following the `MatchDetailsPage` idiom:
  `routeName`, `routePath`, `path({friendId})`). The `FriendModel` is passed via
  GoRouter `extra` for the header; stats compute from `friendId` +
  `MatchHistoryBloc`, so the page still functions if `extra` is absent.

## Copy / localization

New user-facing strings on this screen use inline English constants, consistent
with the existing stats tooltips (`stats_overview.dart`) and the already-inline
`No data available` / `No friends found` strings in this area. Localization keys
are deferred (app supports en/es; the existing stats screen is already partially
hardcoded). Noted as follow-up, not a v1 blocker.

## Testing

- **Calculator unit tests** (the correctness core): shared-pod filter (both ids
  required, distinct seats, unparseable dropped), `timeOfDeath` ordering, wins via
  `winnerId`, survival-fraction normalization + clamp, per-clock 21s vs volume,
  Final Two, Their Go-To modal selection, expected-wins sum, empty/edge inputs.
- **Bloc tests**: compile → loaded; failure path.
- **`MatchDetailsBloc` tests**: `AssignSeatIdentity` for me / friend / unassign,
  and the one-seat-per-identity strip.
- **Widget tests**: friend page renders tiles + gating + empty state; friends
  list tap navigates; assignment sheet lists Me + friends and dispatches.

## Accepted v1 limitations (documented)

- Concessions look like deaths (no concession data) — an early scooper reads as
  "beaten" in the Ledger.
- Commander damage is archetype-sparse — Beatdown/21s no-show for combo/
  spellslinger pairs (by design; gated, not shown as zeros).
- "Who killed you most" — the best Commander pairwise stat — needs a `killedBy`
  field that doesn't exist yet. Top of the future-work wishlist in the consult
  note.
- Existing global stat `timesKilledByCommander` over-reports by summing both
  Partner clocks (`stats_overview_bloc.dart:506`). Out of scope here; flagged for
  a separate fix so the pattern isn't copied.
```
