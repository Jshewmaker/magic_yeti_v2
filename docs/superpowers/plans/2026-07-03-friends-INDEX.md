# Friends Feature — Plan Index

Spec: docs/superpowers/specs/2026-07-03-friends-feature-design.md
Branch: feat/friends-hardening

| Plan | Scope (spec phases) | Status |
|---|---|---|
| A `2026-07-03-friends-a-backend-foundation.md` | Functions + rules + private PIN (1) | complete |
| B (not yet written) | Legacy gate + game fan-out (2–3) | pending |
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

**Plan B must own:**
- `hasPin` self-healing — an old client's full-doc `set()` can wipe the `hasPin`
  flag; `migrateLegacyPin` doesn't repair it once the legacy `pin` field is
  already gone (no signal left to migrate from). The gate that decides whether a
  friend has a PIN must not false-negative in this case.
- A `PinNotSet` result variant — today `failed-precondition` (no PIN set) maps to
  the client's `PinCheckUnavailable`, which shows a misleading "check your
  connection" message for a friend who simply never set a PIN.
- A top-of-file TRANSITIONAL header comment in `firestore.rules` marking the
  rules that only exist to support the legacy-PIN fallback, so they're easy to
  find and remove once migration is complete.
- The force-upgrade decision itself (mechanism exists in `AppBloc`; policy for
  when to trip it for this feature is not yet decided).

**Plan D note:** decide whether `UserProfileModel` should adopt
`includeIfNull: false` (as CLAUDE.md's documented convention claims all models
do) or whether CLAUDE.md should be corrected. Today the model has no
`includeIfNull`, so `toJson()` always serializes `pin` — including explicit
`null` — which is precisely what made the onboarding-erases-legacy-PIN bug
(Fix 2 in the final-review wave) possible. Whichever way this is decided, audit
other full-doc `set()` call sites for the same hazard.
