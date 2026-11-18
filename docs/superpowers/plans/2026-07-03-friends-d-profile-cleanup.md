# Friends Plan D: Profile Completion & Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the feature: account-deletion cleanup, the profile page rebuilt on `UserProfileModel` with PIN change and friend-code sharing, the game-over debt from the Plan B review, serialization-convention alignment, UX honesty fixes, and the l10n/docs sweep.

**Architecture:** Spec phases 6–7 of `docs/superpowers/specs/2026-07-03-friends-feature-design.md` plus every "Plan D must own / note" item in `docs/superpowers/plans/2026-07-03-friends-INDEX.md`. One new Cloud Function (`onUserDeleted`, a **v1 auth trigger** — v2 has no user-deletion trigger; v1 and v2 coexist in one codebase). Everything else is client work on established patterns.

**Tech Stack:** unchanged.

## Global Constraints

- Environment: rules suite via `npx firebase-tools@14.9.0 emulators:exec --only firestore "npm --prefix functions run test:rules"`; ALWAYS pipe flutter output through `tail -5`; Bash timeout 300000; no flutter clean/process kills. Analyzer baseline: **168** (documented lineage in `.superpowers/sdd/progress.md`); no NEW hand-written issues (new generated `.g.dart` infos documented if unavoidable).
- Deletion semantics (spec): removing an account deletes the user's doc tree (profile, `private/`, `blocks/`, their own `matches/`), friendship edges BOTH directions, friendRequests involving them (any status, both directions), and block docs OF them in others' lists. `games/` docs and OTHER players' match copies persist.
- PIN change from the profile page requires NO old PIN (decision #5); it calls the existing `setPin` (salted, private credentials doc).
- Profile submit must never regress the Fix-2 class of bug: carry `pin: existingProfile.pin` (and `hasPin`, `friendCode`, `onboardingComplete`, `imageUrl`, `isAnonymous`, `email`) through the full-doc `set()` — edits only touch username/firstName/lastName/bio.
- `includeIfNull: false` adopted on ALL `firebase_database_repository` models missing it (aligns reality with CLAUDE.md's stated convention). `updateUserProfile` remains a full-doc `set()` — omitted/null fields vanish either way, so behavior is unchanged for full-set paths; the change eliminates explicit-null hazards on any future merge-path writes.
- All new user-facing strings in BOTH arb files + gen-l10n; the sweep localizes the previously-hardcoded friends-list dialog strings.
- TDD per task; commit per task; branch `feat/friends-hardening`; no deploys.

---

### Task 1: `onUserDeleted` cleanup trigger

**Files:**
- Create: `functions/src/on-user-deleted.ts`
- Modify: `functions/src/index.ts`
- Create: `functions/test/rules/on-user-deleted.integration.test.ts`

**Interfaces:**
- Consumes: edge docs carry `userId` (rules-enforced == key); block docs carry `userId` (BlockedUserModel.toJson).
- Produces: `export const onUserDeleted = functionsV1.auth.user().onDelete(...)` (import `firebase-functions/v1` as `functionsV1`).

Cleanup, in one handler (order matters only for readability; each step idempotent):
1. `db.recursiveDelete(db.doc('users/{uid}'))` — profile + private + blocks + own matches.
2. `db.recursiveDelete(db.doc('friends/{uid}'))` — own friend list.
3. `collectionGroup('friendList').where('userId', '==', uid)` → batch-delete (self-edges in others' lists).
4. `friendRequests` where `senderId == uid` and where `receiverId == uid` (NO status filter — declined docs go too; the suppression marker is moot once the account is gone) → batch-delete.
5. `collectionGroup('blocks').where('userId', '==', uid)` → batch-delete (block docs OF this user in others' lists; frees the doc-id slot if they re-register).
Games untouched.

**Test** (integration, wrap the v1 handler: `testEnv.wrap(onUserDeleted)` called with `{ uid: 'victim' }`-shaped user record — firebase-functions-test supports v1 auth triggers directly; seed: victim profile + private/credentials + blocks/other + matches/g1, friends/victim/friendList/friend1, friends/friend1/friendList/victim, friendRequests victim_friend1 (pending) + friend2_victim (declined), users/friend1/blocks/victim (with userId field), games/g1, users/friend1/matches/g1). Assert after firing: every victim-rooted doc gone, friend1's edge-to-victim gone, both requests gone, friend1's block-of-victim gone, `games/g1` and `users/friend1/matches/g1` INTACT.
NOTE: collectionGroup queries in the Admin SDK against the emulator work without manual indexes. If `testEnv.wrap` for the v1 auth trigger needs a different envelope, adapt the harness only; the cleanup contract is binding.

Steps: failing test → RED (module not found) → implement → GREEN (full emulator suite + pure suite) → commit `feat: onUserDeleted trigger cleans the social graph, keeping shared game history`.

---

### Task 2: Game-over debt — failure UX, self-slot unlink, props, widget hardening

**Files:**
- Modify: `lib/life_counter/bloc/game_over_bloc.dart` + `game_over_state.dart`
- Modify: `lib/life_counter/view/game_over_page.dart`
- Modify: `test/life_counter/bloc/game_over_bloc_test.dart`, `test/life_counter/view/game_over_page_test.dart`
- Modify: `lib/l10n/arb/app_en.arb` + `app_es.arb` (one key: `gameSaveFailedError` — "Couldn't save the game. Check your connection and try again." / es "No se pudo guardar la partida. Revisa tu conexión e inténtalo de nuevo.")

Changes (TDD each):
1. **State:** add `status` and `gameModel` to `GameOverState.props` (currently omitted — Equatable swallows status emissions).
2. **Failure surfacing:** wrap `saveGameStats` in try/catch → emit `GameOverStatus.failure`. Move navigation out of the buttons' `onPressed` into a `BlocListener<GameOverBloc, GameOverState>` on the view: buttons ONLY dispatch `SendGameOverStatsEvent` (plus set an intent — add a `GameOverExitIntent { home, playAgain }` field to the event or state so the listener knows where to go); on `success` the listener performs the existing navigation (+ the GameReset/Timer events for playAgain); on `failure` it shows a `gameSaveFailedError` snackbar and re-enables the buttons (buttons disabled while `status == loading`). Keep the game restorable (do NOT reset on failure).
3. **Self-slot unlink:** in the placement map, a slot whose `firebaseId == event.userId` but is NOT the selected slot gets `firebaseId: () => null` (the user disowned it by selecting another slot or notPlaying); foreign ids still preserved; the selected-slot guard unchanged. Bloc tests: switch-slot (old self slot unlinked, new gets uid), notPlaying (self slot unlinked, no slot has uid).
4. **Widget hardening:** give the account-owner dropdown a `ValueKey('game_over_account_owner_dropdown')` and switch the widget test lookup from positional `.last` to the key; wrap the account-owner label `Row`'s text in `Flexible` (Spanish overflow); shrink the test viewport back toward realistic (keep whatever still passes — the overflow fix should allow ~1280×800).

Steps: RED (props test: two states differing only in status must be unequal; failure-emission test; unlink tests; widget key/overflow tests) → implement → GREEN (test/life_counter + full root + analyze) → commit `fix: game-over save failures surface before navigation; disowned slots unlink`.

---

### Task 3: `includeIfNull: false` convention alignment

**Files:**
- Modify: every model in `packages/firebase_database_repository/lib/models/` whose `@JsonSerializable` lacks `includeIfNull: false` (audit all; at minimum `user_profile_model.dart`) + regenerate `.g.dart`
- Modify: `packages/firebase_database_repository/test/models/user_profile_model_test.dart` (add: `toJson()` of a model with null `pin` contains NO `pin` key)

Audit note for the implementer: grep the package's models for `@JsonSerializable`; `GameModel` and `Player` (player_repository) serialize into game docs — GameModel lives in this package? Check; apply the annotation ONLY within firebase_database_repository models and verify no test depends on explicit-null keys (run the FULL package + root suites). The onboarding pin-carry test must still pass (carry of a NON-null legacy pin still serializes; null pin now omits the key — same full-set outcome).

Steps: failing toJson-omits-null test → implement annotation(s) + codegen → GREEN (package + root + analyze; watch for generated-info analyzer deltas — document if any) → commit `chore: adopt includeIfNull:false across firebase_database_repository models`.

---

### Task 4: Profile page rebuilt on `UserProfileModel` (+ PIN change, friend-code share)

**Files:**
- Modify: `lib/profile/bloc/profile_bloc.dart` + state/event files
- Modify: `lib/profile/view/profile_page.dart`
- Modify: `lib/l10n/arb/*` (keys: `changePinTitle` "Change PIN", `changePinDescription` "Your PIN confirms your identity when friends add you to a game.", `newPinLabel` "New PIN", `pinChangedMessage` "PIN updated!", `shareFriendCodeTooltip` "Share friend code", `profileSavedMessage` "Profile saved", `profileSaveFailedMessage` "Couldn't save your profile. Try again." + es)
- Test: `test/profile/bloc/profile_bloc_test.dart`, `test/profile/view/profile_page_test.dart` (create if missing)

Bloc rework (keep event names where they exist):
- New `ProfileLoadRequested(userId)` on creation: `getUserProfileOnce` → state carries the full `UserProfileModel` (loading/loaded/failure statuses). Constructor keeps the auth `User` only for id/email display.
- `_onSubmitted` (currently commented out): build the save model from the LOADED profile — `loaded.copyWith(username: ..., firstName: ..., lastName: ..., bio: ...)` — so `pin`/`hasPin`/`friendCode`/`onboardingComplete`/`imageUrl` are carried automatically (Fix-2-class regression impossible); `updateUserProfile(userId, model)`; success flips `isEditing` off and refreshes the loaded profile. Email becomes READ-ONLY display (auth-managed; drop `ProfileEmailChanged` usage from the form — keep the event registered as a no-op removal or delete it and its call sites).
- New `ProfilePinChanged(String pin)` (reuses the `Pin` formz input) + `ProfilePinSubmitted`: valid 4-digit → `setPin(userId, pin)` → success message state (transient flag or status enum value `pinSaved`). NO old-PIN prompt (decision #5 — note it in a comment).
- Delete flow unchanged (Task 1's trigger now does the Firestore cleanup server-side — add that comment).

Page rework: render username/name/bio from the loaded profile (fallback shimmer/spinner while loading); friend code row keeps the existing copy button and gains a share icon (`Share.share` if `share_plus` is already a dependency — CHECK pubspec; if absent, keep copy-only and note it — do NOT add a new dependency for this); PIN change section with the new-PIN field + save; snackbars for saved/failed/pinChanged driven by a BlocListener.

Steps: bloc tests RED (load, submit-carries-pin [capture the model passed to updateUserProfile and assert pin/friendCode/hasPin preserved], pin-submit calls setPin, failure paths) → implement → widget tests (renders loaded profile fields; PIN section present) → GREEN (test/profile + full root + analyze) → commit `feat: profile page on UserProfileModel with PIN change and friend-code sharing`.

---

### Task 5: Search-accept honesty + anonymous placeholders

**Files:**
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` (`addFriendRequest` guard order)
- Modify: `packages/firebase_database_repository/test/src/friend_request_lifecycle_test.dart`
- Modify: `lib/player/view/customize_player_page.dart` (`_FriendSection`)
- Modify: `lib/friends_list/search_user/search_user_page.dart`
- Modify: `lib/l10n/arb/*` (keys: `signInToLinkFriends` "Sign in to link friends to players." / es; `signInToSearchFriends` "Sign in to add friends." / es)
- Test: extend `test/player/` + `test/friends_list/` widget tests

Changes:
1. **Guard reorder** (C-review triage item 2): in `addFriendRequest`, check the REVERSE-pending query BEFORE the own-doc declined short-circuit, so "Alice declined Bob; Bob taps Accept on Alice's later request from the search card" auto-accepts instead of a silent fake 'sent'. Order becomes: self → already-friends → reverse-pending (auto-accept) → own-doc (declined→sent / pending→alreadyPending) → create. Update/extend lifecycle tests: the declined-then-reverse-pending case now returns `autoAccepted` and writes both edges (rules-legal: pending doc exists; verify the accept batch direction passes the exact same disjuncts as the normal auto-accept — it does, same code path).
2. **Anonymous placeholders:** in `_FriendSection`, when `context.read<AppBloc>().state.status == AppStatus.anonymous` (or the user `isAnonymous`), render the `signInToLinkFriends` copy instead of the friend list/loader; in the search page, same pattern with `signInToSearchFriends` (the callable rejects anonymous anyway — this replaces a confusing error with intentional copy). Widget tests for both anonymous states.

Steps: RED → implement → GREEN (package + root + analyze) → commit `fix: reverse-pending wins over declined suppression; anonymous states get intentional copy`.

---

### Task 6: l10n sweep + stale-doc rewrite

**Files:**
- Modify: `lib/friends_list/friends_list/friends_list.dart` (localize `_confirmRemoveFriend` title/body/Cancel/Remove + the popup-menu labels; keys: `removeFriendAction` "Remove", `removeFriendConfirmTitle` "Remove {name}?", `removeFriendConfirmBody` "They won't be notified. You can add each other again anytime." + es; reuse `cancelTextButton`)
- Sweep: grep `lib/friends_list lib/player/view lib/life_counter lib/onboarding lib/profile` for remaining hardcoded user-facing string literals introduced on this branch (Text('...') with English prose); localize any found (report the list). Known one: onboarding_form's failure snackbar 'Failed to save profile. Please try again.' → `onboardingSaveFailedMessage` + es.
- Rewrite: `docs/friends_feature_plan.md` — replace the stale plan (keep the title) with a short "as shipped" summary: what the feature does today, pointers to the spec/INDEX, the deploy gates, and the PIN/blocking security model in five bullets. Delete the superseded-banner + old body.

Steps: RED (widget test asserting the localized remove-dialog strings render) → implement → gen-l10n → GREEN (root suite + analyze) → commit `chore: localize remaining friends-feature strings; rewrite stale feature doc`.

---

### Task 7: Verification + INDEX close-out

- Full battery (root analyze/test, package test, functions build + pure test, emulator rules suite) — all green.
- INDEX: Plan D row complete; "Plan D must own"/notes sections converted to "Resolved in Plan D" (with the users-list wire-bypass residual EXPLICITLY retained as the one open hardening follow-up, plus the force-upgrade deploy decision); CLAUDE.md's `includeIfNull` claim now true (note it).
- Commit `chore: verify friends plan D; close out index`.
