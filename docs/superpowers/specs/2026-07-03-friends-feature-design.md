# Friends Feature — Hardening & Completion Design

**Date:** 2026-07-03
**Status:** Approved
**Supersedes:** `docs/friends_feature_plan.md` (stale — most of its "missing" items are implemented on main)

## Context

Magic Yeti is played by people sitting around one table, usually on one device. The friends
feature lets a logged-in host add friends by friend code, then link a friend's account to a
player slot during game setup so the finished game lands in *every* linked player's match
history — not just the host's. The safety rail is a 4-digit PIN: linking your account on
someone else's device requires entering *your* PIN. The one hard constraint: friends must
never have to log in on the host's device.

### What already exists on main (verified 2026-07-03)

- Friend codes (`YETI-XXXX`), generation, and search: `generateUniqueFriendCode`,
  `searchByFriendCode` in `packages/firebase_database_repository/lib/src/firebase_database_repository.dart`
- Friend request send/accept/decline/remove flows, models, BLoCs, and UI
  (`lib/friends_list/`), including mutual-request auto-accept and relationship status
- 4-digit PIN: `Pin` formz input, `hashPin`/`validatePin`/`setPin` (SHA-256, unsalted),
  stored as a `pin` field on the world-readable user profile doc
- Onboarding: 4-step wizard (identity → PIN → picture → bio) at `lib/onboarding/`;
  username and PIN steps are required; gated by `UserProfileModel.onboardingComplete`
  via `AppBloc` → `AppStatus.onboardingRequired` → router redirect
- Friend selection on the customize player page (`_FriendSection` in
  `lib/player/view/customize_player_page.dart`): pick friend → PIN dialog →
  `validatePin` → `firebaseId` set on the `Player` at save
- Post-game sync: `GameOverBloc` saves to `games/{docId}` then client-side fans out to
  `users/{firebaseId}/matches/{docId}` for every linked player (`syncGameToPlayers`)
- Game-code import for non-friends: 4-char `roomId` on `GameModel`; another user enters
  it on the home page → `getGame(roomId)` → copy into their own `matches` subcollection

### Why more work is needed

- **No Firestore security rules are versioned in the repo.** The current design depends on
  permissive rules: the host's client writes into *other users'* `matches` subcollections,
  and PIN hashes sit on world-readable profile docs. An unsalted SHA-256 of a 4-digit PIN
  is a 10,000-candidate brute force for anyone who can read the doc.
- **No PIN attempt limiting** anywhere; the PIN dialog allows unlimited retries.
- **Legacy loopholes:** a profile with an empty-string `pin` passes the onboarding PIN step
  (`existingPinHash` non-null check), and users with `onboardingComplete: true` but a
  missing username/PIN are never re-prompted.
- **Game-over overwrite bug:** the "which slot is mine" picker in `GameOverBloc`
  unconditionally assigns the host's `firebaseId` to the selected slot, clobbering a slot
  already PIN-linked to a friend.
- **Profile page is unfinished:** reads the auth `User` instead of `UserProfileModel`;
  `ProfileBloc` submit is stubbed; no PIN change UI; no block management.
- **No abuse rails:** declined friend requests can be re-sent forever; no blocking.

### Decisions (made with Josh, 2026-07-03)

1. **Legacy enforcement:** reuse the existing onboarding gate (no new bottom sheet).
2. **Backend:** add Cloud Functions (Blaze plan accepted) + versioned Firestore rules.
3. **PIN frequency:** PIN required on **every** link — no trusted-device state.
4. **Abuse protection:** full blocking ships in this iteration.
5. PIN change from the profile page requires no old PIN — a logged-in session is stronger
   proof of identity than 4 digits.
6. Synced match-history copies are immutable snapshots: host edits/deletes do not
   propagate; unfriending/blocking does not remove already-synced games.

## Goals

- Enforce name + PIN for all users (new and legacy) with one unskippable path.
- Move every cross-user operation server-side; lock Firestore rules down to match.
- Rate-limit and scope PIN validation so the rail actually holds.
- Ship full blocking (hidden from search, requests refused, unselectable in games).
- Finish the profile page (PIN change, friend code share, blocked users).
- Fix the game-over `firebaseId` overwrite bug.
- Keep the game-code import flow working unchanged for non-friends.

## Non-goals (future work)

- Viewing a friend's stats from the friends list
- Push notifications / badges for friend requests beyond the existing load-time count
- Trusted devices / "remember this device" PIN skips
- Editing or retracting synced games across accounts

## Architecture: clients read, functions write

Anything that touches another user's data moves into Cloud Functions (TypeScript, in a new
`functions/` directory, developed against the Firebase emulator suite). Clients keep reading
via streams/queries; social-graph mutations, PIN checks, and game fan-out become callables
or triggers. `firestore.rules` is added to the repo and wired into `firebase.json`.

### Data model changes

| Path | Change |
|---|---|
| `users/{uid}` | `pin` field **deprecated** (lazily migrated out, then removed from `UserProfileModel`); new `isComplete` getter (username non-empty AND has PIN AND `onboardingComplete`) — completeness of PIN is tracked via a `hasPin` boolean on the profile so the client never needs the hash |
| `users/{uid}/private/credentials` | **New.** `{ pinHash, salt, updatedAt }`. Salted SHA-256 for new PINs; legacy hashes carried over unsalted (`salt: null`) until the user changes their PIN. Owner-only rules; functions read via Admin SDK |
| `users/{uid}/blocks/{blockedUid}` | **New.** `{ blockedAt, username, imageUrl }` (denormalized for the management UI). Owner-readable; function-write-only |
| `pinAttempts/{callerUid}_{targetUid}` | **New.** `{ failCount, lockedUntil, updatedAt }`. No client access; function-only |
| `friendRequests/{id}` | `status` gains `declined`; declined docs are retained (they power re-send suppression) instead of being deleted |
| `games/{docId}`, `Player.firebaseId`, `GameModel` | Unchanged |

### Cloud Functions

All callables require an authenticated, non-anonymous caller and return typed error codes
(`unauthenticated`, `permission-denied`, `failed-precondition`, `resource-exhausted`, `not-found`).

1. **`validatePin({ targetUserId, pin })` → `{ valid }`**
   Preconditions: caller is a friend of target (checked server-side — strangers can't
   attempt); target not currently locked out for this caller. Reads
   `private/credentials`, falling back to the legacy `users/{uid}.pin` field for
   not-yet-migrated accounts. On failure increments `pinAttempts`; **5 failures → 15-minute
   lockout** for that caller→target pair (`resource-exhausted`, with `lockedUntil` in
   details). Success resets the counter.
2. **`searchByFriendCode({ code })` → profile summary or not-found**
   Replaces the client-side Firestore query. Returns not-found when either party has
   blocked the other. Response carries only public profile fields + relationship status.
3. **`sendFriendRequest({ receiverId })` → result enum**
   Moves existing logic server-side: self-check, already-friends, pending, mutual
   auto-accept — plus: refuses when blocked in either direction (`permission-denied`
   disguised as `sent` to avoid leaking block status), and when a `declined` request from
   this sender exists, silently no-ops returning `sent` (receiver never sees it again).
4. **`acceptFriendRequest({ requestId })` / `declineFriendRequest({ requestId })` /
   `removeFriend({ friendId })`**
   Server-side ports of the existing batch writes. Decline sets `status: 'declined'`
   (doc retained). Only the request's receiver may accept/decline.
5. **`blockUser({ targetUid })` / `unblockUser({ targetUid })`**
   Block atomically: removes friendship edges both ways, deletes pending requests both
   ways, writes the block doc. Unblock removes the block doc only (no auto re-friend).
6. **Trigger `onGameCreated` (`games/{docId}` create)**
   Reads `players[].firebaseId`, dedupes, writes the game to each linked player's
   `users/{id}/matches/{docId}` (host included). Idempotent (doc id = game id), retries
   enabled. Replaces the client-side `syncGameToPlayers` call.
7. **Trigger `onUserDeleted` (Auth delete)**
   Cleans up: profile + private subcollections, friend edges both directions, pending
   requests both directions, block docs both directions. Games and other players' match
   copies persist (it's their history too).

### Firestore rules summary

| Path | Read | Write |
|---|---|---|
| `users/{uid}` | any signed-in user | owner only |
| `users/{uid}/private/**` | owner only | owner only (functions bypass) |
| `users/{uid}/blocks/**` | owner only | functions only |
| `users/{uid}/matches/**` | owner only | owner only (covers game-code import; fan-out via functions) |
| `games/{id}` | any signed-in user (game-code lookup) | create: any signed-in; update/delete: `hostId` only |
| `friends/{uid}/friendList/**` | owner only | functions only |
| `friendRequests/{id}` | sender or receiver | functions only |
| `pinAttempts/**` | none | functions only |

### PIN migration (lazy)

On login, the client moves its **own** `pin` field into `private/credentials` and clears
the profile field, setting `hasPin: true`. This is the **only** direct client write to
`private/credentials`; all new/changed PINs go through the `setPin` callable, which salts
and hashes server-side. The migration runs inside the AppBloc profile load, **before**
completeness is evaluated, and completeness treats a legacy non-empty `pin` field as
having a PIN — so already-PIN'd legacy users are never bounced into onboarding. Friends
who haven't logged in since the update stay selectable because `validatePin` falls back to
the legacy field via Admin SDK. `UserProfileModel.pin` is removed once the fallback is
retired.

## Client changes

1. **AppBloc gate** (`lib/app/bloc/app_bloc.dart`): emit `onboardingRequired` when
   `profile == null || !profile.isComplete`. Legacy users re-enter the (pre-filled)
   wizard and complete only what's missing. The offline fallback to `authenticated`
   stays — PIN linking is unusable offline anyway, and the gate re-arms next online
   launch. Anonymous sessions bypass the gate as today.
2. **Onboarding** (`lib/onboarding/bloc/onboarding_bloc.dart`): seed `existingPinHash`
   as null when the stored value is empty (closes the empty-PIN loophole); submit writes
   the PIN to `private/credentials` + `hasPin` instead of the profile field.
3. **Repository** (`firebase_database_repository`): `searchByFriendCode`,
   `addFriendRequest`, `acceptFriendRequest`, `declineFriendRequest`, `removeFriend`,
   `validatePin`, `setPin` become callable invocations (`setPin` salts + hashes
   server-side); new `blockUser`/`unblockUser`/
   `getBlockedUsers`; `syncGameToPlayers` deleted. BLoC events/states are unchanged
   except where noted.
4. **Customize player page**: PIN dialog gains lockout and offline states ("try again in
   N minutes" / "PIN check needs a connection"); selecting a friend already linked to
   another slot in this game is prevented at selection; anonymous host sees a
   "Sign in to link friends" placeholder instead of the friend list.
5. **GameOverBloc / game over page**: slots with a `firebaseId` belonging to someone other
   than the host are excluded from the "which slot is mine" picker and shown with a
   linked badge; if the host already linked their own slot at setup it is preselected.
   The client fan-out call is removed (trigger owns it).
6. **Profile page**: rebuilt on `UserProfileModel`; implement `ProfileBloc` submit;
   PIN change (new PIN + confirm, no old PIN); friend code with copy/share; entry point
   to a blocked-users screen (list + unblock).
7. **Friends list**: block action on friend cards and search results (with confirm
   dialog); blocked-users management screen.
8. **Localization**: all new strings in `app_en.arb` and `app_es.arb`.

## Error handling

- Callable failures surface as retryable snackbars with distinct copy for offline vs.
  server error; nothing crashes game setup — a failed link leaves the slot in manual-name
  mode.
- PIN dialog distinguishes wrong PIN, lockout (shows remaining minutes), and offline.
- Game save: host's `games/` write is the only client-critical path; fan-out failures
  retry server-side and never block the game-over screen.
- Blocked interactions never reveal block status (requests appear "sent"; search returns
  not-found).

## Testing

- **Bloc tests** for every changed bloc (AppBloc gate matrix incl. legacy/empty-PIN cases,
  onboarding, customization PIN states, game-over guard, profile submit, block flows).
- **Repository tests** with a faked functions client (success, each error code, offline).
- **Functions tests** against the Firebase emulator: PIN validation incl. rate limiting,
  friendship precondition, legacy-hash fallback; request lifecycle incl. declined
  suppression and block refusal; fan-out idempotency; deletion cleanup.
- **Widget tests**: PIN dialog states, friend section anonymous state, game-over picker
  exclusions, blocked-users screen.
- **Manual integration pass**: sign up → code + PIN → add friend → block/unblock → link in
  game (right PIN, wrong PIN ×5 → lockout) → finish game → both histories updated →
  game-code import on a third, non-friend account.

## Build order

Each phase is independently shippable:

1. **Backend foundation** — `functions/` scaffold, emulator config, `firestore.rules`,
   `validatePin` callable + private credentials + lazy migration + rate limiting; client
   PIN calls switch over.
2. **Legacy enforcement** — AppBloc gate extension, `isComplete`, empty-PIN fix.
3. **Game sync** — `onGameCreated` fan-out, remove client fan-out, game-over picker guard.
4. **Social graph callables** — request/accept/decline/remove moved server-side, declined
   suppression.
5. **Blocking** — block/unblock callables, search callable, block UI + management screen.
6. **Profile completion** — ProfileBloc submit, PIN change, friend code share.
7. **Cleanup** — `onUserDeleted`, rewrite `docs/friends_feature_plan.md`, l10n sweep,
   remove deprecated `pin` field path once migration fallback is retired.
