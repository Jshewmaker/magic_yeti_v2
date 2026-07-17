# Friends — Live Request State — Design

**Date:** 2026-07-16
**Status:** Proposed

## Problem

Three reported symptoms share one root cause: **there is no live source of truth
for friend-request state**, so every surface that wants to display it invents its
own one-shot read, and nothing can invalidate those reads.

1. **No home indication of a pending request.** No badge, dot, or count exists
   anywhere on home. This is not a regression from the recent home restructure —
   the deleted `lib/home/home_page.dart` had none either. Both entry points to
   friends are static `Icons.people` buttons: the phone AppBar action
   (`lib/home/view/home_page.dart:129`) and the tablet section header
   (`lib/home/view/home_page.dart:83`, rendered by
   `lib/home/widgets/section_header.dart:48`).

2. **Accepting a request does not clear the badge.** The app's only request count
   is the Requests tab badge (`lib/friends_list/friends_list_page.dart:82`),
   driven by a private `_requestCount` field loaded exactly once in `initState`
   via a direct repository call that bypasses the bloc entirely
   (`lib/friends_list/friends_list_page.dart:29-46`). Accepting runs through
   `FriendRequestBloc`, which filters its own list in memory and has no path back
   to that field, so the number stays frozen until the page is popped and
   re-pushed. The Friends tab has the mirror-image bug: accepting never triggers
   `LoadFriends`, so the new friend does not appear until remount.

3. **No real-time listener, and no pull-to-refresh either.** Both
   `getFriends` (`packages/firebase_database_repository/lib/src/firebase_database_repository.dart:622`)
   and `getFriendRequests` (`:643`) are one-shot `.get()` calls. `RefreshIndicator`
   has zero matches across `lib/`, so today there is no way for a user to refresh
   either list short of leaving the page. This is a gap in the friends path, not
   house style — the same repository already streams blocked users (`:883`),
   games (`:225`), and user profiles (`:357`).

Symptom 2 is worth dwelling on, because it is the concrete cost of holding server
data in widget `State`: the value had no external invalidation path, so a domain
event that logically changed it could not reach it. This spec fixes the cause,
not the symptom.

### Adjacent violation, in scope

`lib/stats_overview/widgets/stats_overview.dart:90` holds `_selectedRange` in
widget `State`, and `_filterGames` (`:64-77`) computes date cutoffs and filters
the game list *inside the State class* before handing the result to
`StatsOverviewBloc`. The `setState` is the smaller half; the real problem is
domain logic living in a widget while the bloc receives pre-chewed input.

A survey of all nine `setState` sites in `lib/` found only these two genuine
violations. The rest are legitimate view ephemera and are explicitly **not**
being changed (see Non-goals).

## Non-goals

- **Head-to-head stats vs a friend.** Separate feature, separate spec. The data
  is already recorded correctly — `Player.firebaseId` carries the friend's real
  uid (`lib/player/view/customize_player_page.dart:105`) and `onGameCreated`
  (`functions/src/on-game-created.ts:22`) fans games out to each linked player's
  history — so nothing is lost by deferring it.
- **`addMatchToPlayerHistory` never stamps `firebaseId`** for the importing user,
  so `_findPlayerInGame`'s `orElse: () => game.players.first`
  (`lib/stats_overview/stats_overview_bloc/stats_overview_bloc.dart:120-125`)
  silently attributes the first player's results to the importer. Real bug,
  unrelated cause, tracked separately.
- **Name-keyed opponent stats.** `_calculateMostCommonOpponent` (`:341`) and
  `_calculateNemesis` (`:365`) bucket on `player.name.toLowerCase()` while
  ignoring the available `firebaseId`. Belongs with the head-to-head work.
- **`setState` for view ephemera stays.** Per the agreed rule — blocs for business
  logic and server state, `setState` for a toggle or an expand — these are
  correct as-is and will not be touched: `_isTapped` press highlights
  (`lib/life_counter/widgets/life_counter_widget.dart:98,103,180,185`), the
  `AnimationController` status listener
  (`lib/tracker/commander_damage_tracker_widget.dart:133`), the `_resetNonce`
  dropdown-resync key (`lib/player/view/customize_player_page.dart:281`),
  `_isExpanded` (`lib/life_counter/view/four_player_game.dart:37`), `_tab`
  (`lib/player/view/widgets/commander_picker_panel.dart:72`), and the
  `StatefulBuilder` dialogs (`lib/profile/view/profile_page.dart:265`,
  `lib/match_details/view/match_details_page.dart:539`).

## Approach

### Repository

Add two streams to `FirebaseDatabaseRepository`, mirroring the existing
`getBlockedUsers` (`:883`) pattern:

```dart
Stream<List<FriendRequestModel>> watchFriendRequests(String userId);
Stream<List<FriendModel>> watchFriends(String userId);
```

These **replace** `getFriendRequests` and `getFriends` rather than sitting
alongside them — every caller converts, so leaving the `.get()` variants would
just preserve the footgun.

`watchFriendRequests` queries `friendRequests` where `receiverId == userId` and
`status == 'pending'` — byte-for-byte the query `getFriendRequests` already runs,
only via `.snapshots()`.

**No deploy gate.** Same query shape and same `list` permission as the existing
`.get()`, so this needs no new Firestore index and no rules change. The change is
client-only.

**No pull-to-refresh.** Symptom 3 asked whether requests need a listener or a
manual refresh; these streams answer it, and adding a `RefreshIndicator` on top
would be dead weight. Firestore listeners reconnect and resync on their own after
a dropped connection or app resume, so there is nothing for a manual pull to do
that the stream has not already done.

### State

**Promote `FriendRequestBloc` to app-root.** It moves into the provider list at
`lib/app/view/app.dart:56`, alongside `MatchHistoryBloc`, and re-subscribes on
auth change using the `BlocListener` at `lib/app/view/app.dart:133-141` as the
template. One bloc, one truth: the home dot and the Requests tab badge read the
same instance, so they cannot diverge, and only one listener is opened.

- `LoadFriendRequests` **stays** and gains `transformer: restartable()` from
  `bloc_concurrency` (already a dependency), exactly as
  `lib/home/match_history_bloc/match_history_bloc.dart:17` does. `emit.forEach`
  never completes on its own, because the stream never closes — so without
  `restartable()` a re-dispatch on auth change would stack a second
  subscription behind the first rather than replacing it.
- **Empty `userId` means "nobody is signed in":** emit `FriendRequestLoaded([])`
  and return without subscribing, mirroring `match_history_bloc.dart:29-38`.
  This *is* the auth gate — anonymous and signed-out users get an empty list and
  no dot, and no listener is ever opened against a uid the rules would reject.
- `AcceptFriendRequest` / `DeclineFriendRequest` stay, **including the
  `priorState` capture and `LegacyFriendRequestException` recovery**
  (`lib/friends_list/requests/bloc/friend_request_bloc.dart:42-61`). Only the
  success-path in-memory filter is removed; the failure paths are untouched.
- **The in-memory filter in the accept handler
  (`lib/friends_list/requests/bloc/friend_request_bloc.dart:38-65`) is deleted.**
  `acceptFriendRequest` ends in `batch.delete(...)` on the request doc
  (`packages/firebase_database_repository/lib/src/firebase_database_repository.dart:576`),
  which makes the stream re-emit without it. Firestore's latency compensation
  fires the local listener before the server acks, so this is instant *and*
  self-healing — the badge clears because the truth changed, not because someone
  remembered to clear it.
App-root wiring mirrors `MatchHistoryBloc` exactly: provide the bloc at
`lib/app/view/app.dart:73` seeded with `..add(LoadFriendRequests(...))`, and
re-dispatch from the existing `BlocListener` at `lib/app/view/app.dart:133-141`.
That listener's `listenWhen` already keys on the helper `_historyUserId`
(`lib/app/view/app.dart:95-97`), which computes exactly the "signed-in uid or
empty" value both blocs need — so it gets generalized to `_signedInUserId` and
the one listener dispatches both events. No second listener, no duplicated
predicate.

**`FriendBloc` stays page-scoped** and converts to `emit.forEach`, exactly like
`lib/friends_list/blocked_users/bloc/blocked_users_bloc.dart:31`. Nothing global
needs the friends list, so promoting it would be ceremony. Accepting writes to
`friendList`, the stream re-emits, and the new friend appears — the second half
of symptom 2, also fixed by the truth changing rather than by refresh wiring.

Delete the stale doc comment at
`lib/friends_list/friends_list/bloc/friend_list_bloc.dart:21` claiming "Ensures
real-time updates using Firestore sync" — false today, true after this change,
and worth stating accurately either way.

### UI

**New `NotificationDot`** at `packages/app_ui/lib/src/widgets/notification_dot.dart`,
exported from `packages/app_ui/lib/src/widgets/widgets.dart` — a plain
`AppColors.red` dot, no count. Used in two places (phone AppBar icon, tablet
`SectionHeader`), which is enough to justify extracting it rather than
duplicating the decoration.

- **Home, phone:** dot on the `Icons.people` AppBar action
  (`lib/home/view/home_page.dart:129`).
- **Home, tablet:** dot on the `SectionHeader` people icon
  (`lib/home/view/home_page.dart:83`); `SectionHeader`
  (`lib/home/widgets/section_header.dart:48`) gains a `showBadge` parameter.
- **Requests tab keeps its count pill.** Home says "something is waiting"; the
  page says how many. The pill stays inline at
  `lib/friends_list/friends_list_page.dart:84-101` — it now has exactly one call
  site, so extracting it would be premature.
- **`FriendsListPage` drops `StatefulWidget` entirely.** `_requestCount`,
  `initState`, and `_loadRequestCount` all delete; the badge reads the app-root
  bloc via `BlocBuilder`. Everything remaining in the widget is
  `DefaultTabController` + `TabBar` + `TabBarView`, none of which needs `State`.
- **`FriendRequestsPage` drops its own `BlocProvider.create`**
  (`lib/friends_list/requests/friend_request_page.dart:23-28`) and reads the
  app-root bloc. This keeps working for both its embedded tab and its standalone
  `/friendRequests` route (`lib/app/app_router/app_router.dart:89`).
- Replace the hardcoded English `'No pending requests'` empty state
  (`lib/friends_list/requests/friend_request_page.dart:52-58`) with an l10n key
  while we are in the file.

### Stats time-range fix — separate commit

Lives in the stats feature, not friends, so it ships as its own commit and does
not gate the friends fix.

- Move `_filterGames` (`lib/stats_overview/widgets/stats_overview.dart:64-77`)
  into `StatsOverviewBloc`.
- Add a `StatsTimeRangeChanged(range)` event; the selected range becomes part of
  `StatsOverviewState`.
- `_selectedRange` and its `setState` (`:90`) delete; the dropdown reads the range
  from bloc state.
- Games continue to be fed in from `MatchHistoryBloc` via the existing
  `BlocListener` (`:97-100`). Having the bloc subscribe to match history directly
  would be cleaner but is out of scope.

## Data flow — accept

```
tap Accept
  → FriendRequestBloc.AcceptFriendRequest
  → repository.acceptFriendRequest  (batch: set both friendList edges, delete request doc)
  → local listeners fire immediately (latency compensation, pre-ack)
      → watchFriendRequests re-emits without the request
          → home dot hides, tab count decrements
      → watchFriends re-emits with the new friend
          → Friends tab shows them
  → server acks; no second UI change
```

No refresh event, no manual invalidation, no cross-widget wiring. Every surface
moves because the underlying truth moved.

## Error handling

- **Stream error** → bloc emits an error state and the dot **hides**. Fail closed:
  a dot that might be wrong is worse than no dot, because it sends the user to a
  page to find nothing.
- **Not authenticated / anonymous** → no subscription, no dot, empty state.
- **`permission-denied` on accept** → preserve the existing
  `LegacyFriendRequestException` path
  (`packages/firebase_database_repository/lib/src/firebase_database_repository.dart:579-585`).
- **Sign-out** → the `BlocListener` at `lib/app/view/app.dart:133-141` must cancel
  the subscription, or the listener leaks and errors against the signed-out uid.

## Testing

- **Repository:** `watchFriendRequests` / `watchFriends` emit on change; match the
  existing repository test setup rather than introducing a new fake.
- **Bloc:** `bloc_test` — stream emission drives state; accept triggers the batch
  and the re-emit empties the list, **with the in-memory filter gone** (this is
  the test that would have caught the original bug).
- **Widget:** dot renders when requests are pending, hides when empty, hides when
  anonymous, hides on stream error.
- **Regression:** the reported bug end to end — a pending request, accept it,
  assert the badge clears with no remount.
- **Stats:** `StatsTimeRangeChanged` filters correctly at each range boundary;
  the cutoff logic keeps its behavior through the move into the bloc.

## Files touched

| File | Change |
|---|---|
| `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` | `getFriends`/`getFriendRequests` → `watchFriends`/`watchFriendRequests` |
| `lib/app/view/app.dart` | provide `FriendRequestBloc` app-root; re-subscribe on auth change |
| `lib/friends_list/requests/bloc/friend_request_bloc.dart` | stream-driven; drop `Load`; delete in-memory filter |
| `lib/friends_list/friends_list/bloc/friend_list_bloc.dart` | `emit.forEach`; fix false doc comment |
| `lib/friends_list/friends_list_page.dart` | `StatefulWidget` → `StatelessWidget`; badge from bloc |
| `lib/friends_list/requests/friend_request_page.dart` | drop own provider; l10n the empty state |
| `lib/home/view/home_page.dart` | dot on both people entry points |
| `lib/home/widgets/section_header.dart` | `showBadge` parameter |
| `packages/app_ui/lib/src/...` | new `NotificationDot` |
| `lib/stats_overview/widgets/stats_overview.dart` | drop `_selectedRange` + `_filterGames` *(separate commit)* |
| `lib/stats_overview/stats_overview_bloc/*` | own the range + filtering *(separate commit)* |
