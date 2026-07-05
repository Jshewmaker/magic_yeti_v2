# Friends Feature — Plan Index

Spec: docs/superpowers/specs/2026-07-03-friends-feature-design.md
Branch: feat/friends-hardening

| Plan | Scope (spec phases) | Status |
|---|---|---|
| A `2026-07-03-friends-a-backend-foundation.md` | Functions + rules + private PIN (1) | complete |
| B `2026-07-03-friends-b-gate-and-sync.md` | Legacy gate + game fan-out (2–3) | complete |
| C (not yet written) | Social graph rules + blocking (4–5) | pending |
| D (not yet written) | Profile page + cleanup (6–7) | pending |

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

**Plan C must own (from the Plan B whole-branch review):**
- Close the trigger-laundered cross-user write path: rules-validate
  `request.resource.data.hostId == request.auth.uid` on `games` create (the only
  client create path already sets it), and once friendship edges are
  rules-enforced, consider gating trigger fan-out to recipients with a
  friendship edge to `hostId`.
- Uid-shape validation in `onGameCreated` (reject `firebaseId` containing `/` —
  today a path-hostile id makes the batch throw and, with `retry: true`,
  starves legitimate recipients for the retry window).
- The B4 malformed-input trigger tests (non-array `players`, missing `hostId`).
- Follow the established TRANSITIONAL test choreography when tightening the
  remaining `friends/*` and `friendRequests` blocks.

**Plan D must own:**
- `GameOverState.props` omits `status`/`gameModel` (Equatable swallows
  loading/success emissions) and `saveGameStats` failures vanish (no failure
  status, navigation already happened) — needed before any save-failure UX.
- "I'm not playing"/slot-switch does not unlink a self-linked slot (stats can
  attribute a slot the user disowned; two slots can carry the same uid).
- Dropdown test lookup by `Key` instead of positional `.last`; wrap the
  account-owner label Row in `Flexible` (real overflow risk with Spanish
  strings).

**Plan D note:** decide whether `UserProfileModel` should adopt
`includeIfNull: false` (as CLAUDE.md's documented convention claims all models
do) or whether CLAUDE.md should be corrected. Today the model has no
`includeIfNull`, so `toJson()` always serializes `pin` — including explicit
`null` — which is precisely what made the onboarding-erases-legacy-PIN bug
(Fix 2 in the final-review wave) possible. Whichever way this is decided, audit
other full-doc `set()` call sites for the same hazard.
