# Friends Flow Review — Username-Only Identity & Name Cleanup

**Date:** 2026-07-07
**Status:** Approved (autonomous goal session; decisions documented below)
**Branch:** feat/friends-hardening
**Builds on:** `2026-07-03-friends-feature-design.md` (hardening plans A–D, complete)

## Context

Goal directive: review the entire friends user flow — signup through in-game friend
linking and cross-account sync — and enforce three requirements:

1. Users must have a username; anyone without one is forced to set it on app open.
2. The username is the identity shown during games and in the friends list.
3. First name / last name are no longer needed; remove all relevance from the code.
4. The flow should follow friends-list best practices.

### Flow as it exists today (verified 2026-07-07)

- **Signup/login** (`lib/sign_up/`, `lib/login/`): email+password, Google, Apple.
  No profile fields collected at signup.
- **Username gate — already exists.** `AppBloc._onUserChanged`
  (`lib/app/bloc/app_bloc.dart:100-145`) fetches the Firestore profile and emits
  `AppStatus.onboardingRequired` unless `UserProfileModel.isComplete`
  (`onboardingComplete && username non-empty && hasPin/legacy pin`,
  `user_profile_model.dart:120-123`). The router redirects that status to
  `/onboarding`, whose step 1 requires a valid username before Next enables.
  Legacy users with incomplete profiles re-enter the pre-filled wizard. Anonymous
  sessions bypass the gate (they cannot use friends features). Offline fetch
  failure falls back to `authenticated` — an accepted decision from the 2026-07-03
  spec (PIN linking is unusable offline; the gate re-arms next online launch).
- **Username display — already correct everywhere that matters.** Friends list
  shows `friend.username` (+ friendCode subtitle); requests show `senderName`,
  which `SearchBloc._onAddFriendRequest` sources from the sender's own profile
  `username`; search results show `username`; a seat linked to "Me" or a friend
  gets the account's username written into the locked `Player.name`, which is what
  the life counter and match history display. Unlinked seats keep a free-typed
  name — intended (guests without accounts).
- **First/last name — collected but never displayed.** Optional fields on
  onboarding step 1 and the profile page, stored on `UserProfileModel`. No UI
  reads them back except those two edit forms. Cloud Functions never touch them.
  The auth-level `User.name` (Firebase `displayName`; Apple sign-in explicitly
  requests the `fullName` scope) is mapped into the model but **unused by any app
  code**.
- **Friends/social backend** (hardening branch, complete): deterministic friend
  request IDs, declined-doc re-send suppression, full two-direction blocking,
  block-aware code/username search callables, rate-limited `validatePin` (5
  fails → 15-min lockout), server-side `onGameCreated` fan-out to
  `users/{uid}/matches`, immutable synced copies, versioned rules + emulator
  tests.

## Requirement analysis

### R1 — Force username on app open: gate exists; harden the edges

No new gate is needed. Gaps found and fixed in this pass:

1. **Whitespace-only usernames pass.** `Username.validator`
   (`packages/form_inputs/lib/src/username.dart`) only checks `isNotEmpty`, so
   `"   "` is accepted by onboarding and the profile page, and
   `isComplete` treats it as complete. Fix: validate the **trimmed** value —
   empty → `empty`, trimmed length < 2 → `tooShort`, > 30 → `tooLong`. Blocs
   save the trimmed value so stored usernames carry no edge whitespace.
   *Min 2 matches the `searchByUsername` 2-character minimum, so every
   username is discoverable by search. `isComplete` itself keeps the loose
   non-empty check — legacy users with short usernames are not bounced into
   onboarding; they only meet the new rule when they next edit the field.*
2. **Profile page shows a generic "save failed" snackbar when the username is
   empty** (open follow-up from Plan D). Fix: inline `errorText` on the username
   field from the formz error, and distinct snackbar copy when save is blocked
   by an invalid username.

### R2 — Username is the displayed identity: verified, no changes

Covered by the current code (see Context). This pass adds no display changes;
regression tests already pin the linked-seat name behavior.

### R3 — Remove firstName/lastName everywhere

**Model & persistence**

- `UserProfileModel`: drop `firstName`/`lastName` fields, `copyWith` params,
  `props` entries; regenerate `user_profile_model.g.dart`.
- No Firestore migration needed: `json_serializable` ignores unknown keys on
  read, and `updateUserProfile` writes the **full document with `set()` (no
  merge)** — stale `firstName`/`lastName` keys disappear from a user's doc on
  their next profile save. Rules don't reference the fields.

**Onboarding** (`lib/onboarding/`)

- Remove `firstName`/`lastName` from state (fields, initial values, copyWith,
  props), the `OnboardingFirstNameChanged`/`OnboardingLastNameChanged` events and
  handlers, the submit payload, and the two `_IdentityStep` text fields with
  their controllers. Step 1 becomes username-only.

**Profile page** (`lib/profile/`)

- Same removal: state fields/copyWith/props, `ProfileFirstNameChanged`/
  `ProfileLastNameChanged` events and handlers, save fallbacks, two form fields.

**Auth layer**

- Remove the unused `User.name` field from
  `packages/authentication_client/.../models/user.dart` (field, copyWith,
  props), the `displayName` mapping in `firebase_authentication_client.dart`'s
  `toUser()` extensions, and stop requesting `AppleIDAuthorizationScopes.fullName`
  at sign-in (keep `email`). The provider display name *is* the user's real
  first+last name; the app's identity is username-only, so we stop collecting it
  (data-minimization). Update package tests that construct `User(name: ...)`.

**Localization & tests**

- Remove `firstNameLabel`/`lastNameLabel` from `app_en.arb`/`app_es.arb`;
  regenerate localizations. Update test fixtures in `profile_bloc_test.dart`,
  `profile_page_test.dart`, and any `User(name:)` constructions.

### R4 — Best-practices assessment

Already aligned with common friends-system practice: request/accept model with
deterministic IDs (no duplicate spam), silent declined-request suppression
(decliner isn't revealed), full bidirectional blocking hidden from search,
secret validation server-side with rate limiting, server-guaranteed history
fan-out, immutable synced snapshots, owner-only match history, denormalized
display data for cheap list rendering.

**Fixed in this pass**

- Username input hardening (R1.1) — prevents blank/unsearchable identities.
- Distinct username error copy on profile save (R1.2).
- `search_user_page` renders raw exception text (`SearchError('Failed to
  search: $e')`) — replace with typed error states mapped to localized,
  user-friendly copy in the UI (pre-existing follow-up, squarely a friends-list
  UX issue).

**Documented follow-ups (out of scope — backend/deploy-gated or product calls)**

- **Username uniqueness** is *not* enforced; `friendCode` is the unique
  discovery key and the profile page says so ("Not unique — others may share
  this name"). Enforcing uniqueness retroactively needs a reserved-names
  registry, a migration for existing duplicates, and function/rules changes —
  a deliberate product decision for Josh, not this pass.
- **Rename staleness:** friends-list entries denormalize `username` at accept
  time; a later rename isn't propagated to existing friend edges/blocks/request
  docs. Fix would be an `onProfileUpdated` fan-out function.
- Restrict `users` collection `list` reads (existing Plan D follow-up).

## Non-goals

- No Cloud Functions, Firestore rules, or index changes — this pass is
  app-client only and adds **no new deploy gates**.
- No username uniqueness enforcement (see above).
- No change to unlinked-seat free-text player names (guests are a feature).
- No removal of the auth `photo` field (profile pictures are still a feature).

## Error handling

- Username field errors render inline via formz error → localized message
  (empty / too short / too long), on both onboarding step 1 and the profile page.
- Profile save blocked by invalid username shows the specific message, not the
  generic save-failed snackbar.
- Search errors show localized friendly copy; the exception detail stays in
  logs, not the UI.

## Testing

- `form_inputs`: unit tests for trim/tooShort/tooLong/valid.
- Onboarding bloc/widget tests: whitespace-only username cannot advance step 1;
  submitted username is trimmed; no first/last events remain.
- Profile bloc/page tests: fixtures lose names; invalid-username save gate emits
  the distinct error; trimmed save.
- Auth package tests: `User` without `name`; Apple scope list contains only
  `email`.
- Search bloc/page tests: typed error states render localized copy.
- Full: `flutter analyze`, root + affected package test suites, regenerate
  codegen and l10n, confirm no `firstName|lastName` references remain outside
  generated localization history.

## Build order

1. `form_inputs` Username validator + tests (foundation, no dependents break).
2. firstName/lastName removal: model + codegen → onboarding → profile → l10n →
   fixtures (single commit-per-layer or one sweep; deletions dominate).
3. Auth `User.name` removal + Apple scope change + package tests.
4. Username UX hardening: trimmed saves, inline errors, distinct profile copy.
5. Search error copy cleanup.
6. Verification sweep + repo-wide grep for leftovers.
