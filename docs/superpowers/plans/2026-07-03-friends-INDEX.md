# Friends Feature — Plan Index

Spec: docs/superpowers/specs/2026-07-03-friends-feature-design.md
Branch: feat/friends-hardening

| Plan | Scope (spec phases) | Status |
|---|---|---|
| A `2026-07-03-friends-a-backend-foundation.md` | Functions + rules + private PIN (1) | complete |
| B `2026-07-03-friends-b-gate-and-sync.md` | Legacy gate + game fan-out (2–3) | complete |
| C `2026-07-03-friends-c-social-graph-blocking.md` | Social graph rules + blocking (4–5) | complete |
| D `2026-07-03-friends-d-profile-cleanup.md` | Profile page + cleanup (6–7) | complete |

**POST-DEPLOY GOTCHA (discovered 2026-07-05, first real production deploy):** if a
multi-function deploy partially fails (one function's build breaks, aborting the
whole operation), any 2nd-gen callable functions that DID finish creating their
underlying Cloud Run service can be left without the public-invoker IAM binding —
they "exist" and every subsequent deploy sees no source change and treats them as
an update (skipping re-applying that binding), so they silently reject ALL traffic
forever with a raw Google-frontend 403 HTML page instead of Firebase's normal JSON
error. This is indistinguishable from a working deploy in `firebase deploy` output.
**Verify any 2nd-gen callable after deploying** with:
`curl -X POST <callable-url> -d '{"data":{}}'` — expect
`{"error":{"status":"UNAUTHENTICATED",...}}` (HTTP 401). A raw HTML "403 Forbidden"
page means the fix is `firebase functions:delete <name> --force` followed by a
fresh deploy, forcing a genuine create instead of an update.

**NATIVE CRASH ON FRIEND SEARCH (found 2026-07-05, root-caused via Console.app crash
report):** the IAM gotcha above was real but was NOT the cause of the on-device
friend-search freeze/crash reported the same day — that symptom is a **native
SIGABRT inside the FirebaseFunctions/FirebaseAuth iOS SDKs themselves**, unrelated
to any app or Cloud Functions code. Root cause: Swift 6.3 (shipped in Xcode 26.4)
has a compiler regression that miscompiles `async let` teardown in optimized
builds, corrupting the Swift Concurrency runtime's task-local stack the moment
`HTTPSCallable.call()` (used by `searchByFriendCode`) tears down its internal
concurrent auth/App Check token fetches — same pattern affects any `FirebaseAuth`
call. Upstream: firebase/firebase-ios-sdk#15974, fixed via PR #15991 (Task-based
rewrite replacing the `async let`), targeted for firebase-ios-sdk 12.12.0 — far
ahead of this repo's currently pinned 11.8.0. Confirmed match: this machine runs
exactly Xcode 26.4 / Swift 6.3.
Fix applied in `ios/Podfile`'s `post_install` hook: force
`SWIFT_OPTIMIZATION_LEVEL = -Onone` on the `FirebaseFunctions` and `FirebaseAuth`
pod targets (all configs), sidestepping the optimizer bug regardless of which
Xcode build configuration CocoaPods compiles them under. This is a toolchain
workaround, not an app code change — remove it once the podspecs are bumped to a
firebase-ios-sdk release containing #15991 (12.12.0+), which requires bumping the
FlutterFire plugin majors (`cloud_functions`, `firebase_auth`, `firebase_core`,
etc.) since this repo currently pins `firebase_core: ^3.8.1` → SDK 11.8.0.

**DEPLOY GATE:** before the first `firebase deploy --only firestore:rules`, export
the project's CURRENT production rules from the Firebase console and diff them
against `firestore.rules` — the console rules were never versioned and may contain
grants this repo doesn't know about. Deployment is run by Josh, not by an agent.

`firebase deploy --only functions` MUST happen before any app release built from
this branch reaches users. The client's PIN validation now calls the `validatePin`
callable exclusively (there is no client-side fallback) — without the function
deployed, every link attempt fails with an "unavailable" error, not a graceful
degrade.

Pre-update app versions validate PINs by reading the profile's legacy `pin` field
directly (there was no callable before this feature). Login-time migration
(`migrateLegacyPin`) deletes that field once the account signs in on an
up-to-date client. Practically: once a friend's account migrates, hosts still
running an old app version will read the (now-deleted) legacy field as empty and
report "Incorrect PIN" even when the PIN is right. This is a **named, accepted
breakage** — to be paired with the existing force-upgrade mechanism when Plan B
ships, so old clients are pushed to update before they can hit this path.

**Resolved in Plan B:**
- `hasPin` self-healing — `migrateLegacyPin` now repairs a wiped flag when the
  private credentials doc exists.
- `PinNotSet` result variant — `failed-precondition` surfaces distinct "friend
  has no PIN" copy instead of "check your connection".
- TRANSITIONAL strategy header added to `firestore.rules`.
- Completeness gate: `AppBloc` routes on `UserProfileModel.isComplete`
  (username + PIN + onboardingComplete); legacy users re-enter the pre-filled
  onboarding wizard.
- Game fan-out is fully server-side (`onGameCreated` trigger); cross-user
  `matches` writes are now DENIED by rules; the game-over `firebaseId`
  overwrite bug is fixed (guard + UI exclusion + "I'm not playing" option).

**Still open (deploy-time policy, Josh's call):** the force-upgrade decision —
the maintenance/force-upgrade mechanism exists via `app_config_repository`;
whether to trip it for this release (pairing with the rules+functions deploy so
old clients can't hit the migrated-PIN and denied-fan-out paths) is decided at
release time, not in code.

**DEPLOY GATE (updated for Plan B):** the Plan B rules tightening (cross-user
`matches` writes denied) and the app's removal of client-side fan-out MUST
deploy together with the `onGameCreated` function: deploying rules without the
function (or shipping the app without deploying either) silently stops ALL
match-history sync — including the host's own copy (the client no longer writes
any matches doc at game end); game saves would succeed while nobody receives
copies.
Order: `firebase deploy --only functions` → `firebase deploy --only
firestore:rules` → app release.

**Resolved in Plan C:**
- Trigger injection closed: `games` create requires `hostId == request.auth.uid`;
  `onGameCreated` rejects path-hostile ids; malformed-input tests added.
  (Friendship-gated fan-out was considered and NOT adopted: hostId is now
  authenticated, players are chosen on the host's device, and gating on edges
  would break the guest/game-code flow — accepted residual: a host can list a
  linked friend who later unfriends them; the game still syncs, which matches
  the "players in the game get the game" product rule.)
- Deterministic friendRequests ids (`{sender}_{receiver}`), declined docs
  retained as permanent suppression markers (pending-only deletes — the
  delete-and-recreate dodge is rules-blocked), block-gated creates, edge
  writes gated on pending requests with `userId == doc key` integrity.
- Full blocking: owner-managed `users/{uid}/blocks`, block-aware
  `searchByFriendCode` callable (block-hiding both directions, fail-closed
  friend-edge direction), client batch block/unblock, blocked-users screen,
  friends-list block action.
  Accepted residual: search block-hiding binds the official client only —
  the `users` collection remains list-readable to any signed-in user at the
  wire level, so a raw-SDK user can still find a blocker by friendCode
  query. Request-create denial and edge gating still hold. Plan D
  candidate: restrict users `list` (requires moving
  generateUniqueFriendCode's uniqueness query server-side).
- **Legacy data note (Josh, deploy-time):** pending requests created before
  this deploy (random doc ids) can be DECLINED but not accepted (accept shows
  "sent from an older version — ask them to re-send"). Optional one-time
  cleanup: delete `friendRequests` docs where the doc id doesn't match
  `{senderId}_{receiverId}` — or just let them drain via decline.

**Resolved in Plan D:**
- `onUserDeleted` auth trigger cleans the deleted user's doc tree, friendship
  edges both directions, requests (any status), and blocks of them — games and
  other players' match copies persist. Accepted residual: v1 auth triggers
  don't retry, so a mid-flight crash can orphan a few edges/requests — they
  fail closed (every rules guard on the missing uid denies) and are cosmetic.

**DEPLOY GATE (updated for Plan D review):** deploy order now starts with
`firebase deploy --only firestore:indexes` — before functions. The
`onUserDeleted` collection-group queries (`collectionGroup('friendList')`,
`collectionGroup('blocks')`, both filtered on `userId`) hard-require the
COLLECTION_GROUP field overrides in `firestore.indexes.json`; Firestore's
automatic indexes are collection-scope only and do not cover them. **The
emulator cannot validate this** — it does not enforce indexes, so
`test:rules` (and any emulator-based test) will pass even if the production
indexes are missing or still building, and cleanup steps 3-6 of
`onUserDeleted` will silently throw `FAILED_PRECONDITION` in production.
Index builds on existing data take time, so deploy indexes first and wait
for the build to reach READY before deploying functions.
BEFORE the first index deploy: export current production indexes
(`firebase firestore:indexes`) and merge them into `firestore.indexes.json`
— the file is declarative and ships `"indexes": []`, so the CLI will offer
to DELETE any console-created composite indexes it doesn't know about
(same never-versioned risk as the rules gate above). Note also that the
fieldOverrides drop Firestore's automatic DESCENDING/array-contains
single-field indexes on `friendList.userId` and `blocks.userId`; nothing
queries those today, but future queries on those fields need the file
extended.
Order: `firebase deploy --only firestore:indexes` → `firebase deploy --only
functions` → `firebase deploy --only firestore:rules` → app release.
- Game-over debt: `GameOverState.props` fixed; save failures now block
  navigation and surface a snackbar with retry (buttons disabled while
  saving, double-submit guarded by a status check — a `droppable()`
  transformer was tried and reverted: its cancellation semantics hang
  `bloc.close()`); disowned self-linked slots unlink on save; dropdown keyed;
  label overflow fixed.
- Profile page rebuilt on `UserProfileModel`: real submit that carries
  pin/hasPin/friendCode through the full-doc set (Fix-2-class regression
  impossible by construction), PIN change with no old-PIN prompt, friend-code
  copy (share deferred — `share_plus` not a dependency), email read-only.
- `includeIfNull: false` adopted on all five firebase_database_repository
  models — CLAUDE.md's stated convention is now true for this package.
- Search-card accept honesty (reverse-pending wins over declined
  suppression); anonymous users get intentional sign-in copy on the friend
  section and search page; `removeFriend` edge deletes are atomic.
- l10n sweep of branch-introduced strings; `docs/friends_feature_plan.md`
  rewritten as the as-shipped feature README.

**Open follow-ups (post-branch):**
- Restrict `users` collection `list` reads (requires moving
  `generateUniqueFriendCode`'s uniqueness query server-side) — closes the
  raw-SDK friendCode-search bypass of block hiding.
- `search_user_page` renders raw exception text on search errors
  (pre-existing pattern).
- The force-upgrade deploy decision (see deploy gates above).
- Distinct "username can't be empty" copy on the profile submit gate
  (currently the generic save-failed snackbar).
- Refresh `state.profile` after a PIN save on the profile page (closes a
  narrow stale-profile window when login migration failed and the user
  changes PIN then saves profile fields in one session).
- CI is red on main for pre-existing repo-wide reasons (formatting +
  spell-check gate the analyze/test jobs) — fix in a dedicated change.
- Consolidate the duplicate delete-account paths (`ProfileBloc`'s
  `ProfileDeleted` handler is test-only/unused by the page; the page and
  `AppBloc` route through `AppUserAccountDeleted`, whose `deleteAccount` call
  is unawaited and surfaces failures nowhere).
- Add logging/analytics to the swallowed `catch` blocks in `GameOverBloc` and
  `ProfileBloc` so failures are observable instead of silently dropped.

**SEARCH BY NAME (post-branch feature, 2026-07-05):** the search box now
auto-detects friend-code-shaped input (`YETI-XXXX`) vs. everything else,
routing the latter to a new block-aware `searchByUsername` callable
(case-insensitive prefix match, 2-char minimum, 10-result cap). Requires:
- A new `usernameLower` field on `UserProfileModel`, derived and force-synced
  by `FirebaseDatabaseRepository.updateUserProfile` on every write — never
  set it directly. `firestore.rules` validates any client-written
  `usernameLower` matches `username.lower()`.
- **DEPLOY GATE:** this needs `firebase deploy --only functions` (new
  `searchByUsername`) AND `firebase deploy --only firestore:rules` (the
  `usernameLower` validation) before release. No index changes — a
  single-field range query gets Firestore's automatic index for free.
  Existing profiles won't have `usernameLower` until their next profile
  save, so name search only finds users who have saved their profile since
  this deploy; friend-code search is unaffected.
