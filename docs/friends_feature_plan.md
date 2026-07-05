# Friends List Feature — Implementation Plan

This document describes the friends feature as it ships today. For the design
rationale and phased build-out, see
[`docs/superpowers/specs/2026-07-03-friends-feature-design.md`](superpowers/specs/2026-07-03-friends-feature-design.md).
For plan-by-plan status and deploy gates, see
[`docs/superpowers/plans/2026-07-03-friends-INDEX.md`](superpowers/plans/2026-07-03-friends-INDEX.md).

## What it does

- **Friend codes.** Every user gets a unique `YETI-XXXX` code at onboarding.
  `searchByFriendCode` is a block-aware callable — it returns "not found" if
  either party has blocked the other, otherwise a public profile summary plus
  relationship status.
- **Friend requests.** Requests use deterministic ids
  (`friendRequests/{senderId}_{receiverId}`), which lets Firestore rules
  enforce the request lifecycle without queries. A mutual request auto-accepts.
  Declining sets `status: declined` and **retains** the doc so a sender can't
  silently re-send — the client checks for a prior declined doc and no-ops
  (UI still shows "sent"). Accept/remove are client batch writes gated by
  rules on the deterministic path.
- **Blocking.** Blocking removes any existing friendship (both edges deleted),
  clears pending requests in both directions, and hides the blocked user from
  friend-code search both ways. The block record itself is one-directional
  (owned by the blocker) and is the actual security boundary; the edge/request
  cleanup is a single atomic batch commit — it either fully applies or fully
  fails, so there's no partial-cleanup state to self-heal from.
- **PIN-gated player linking.** Selecting a friend as a player requires their
  4-digit PIN on every link — there's no trusted-device state. PINs are salted
  SHA-256 hashes stored in a private, owner-only `credentials` subdocument;
  only the `validatePin` callable (Admin SDK) can read them. The callable
  requires the caller to already be friends with the target, and enforces
  **5 failed attempts → 15-minute lockout** per caller→target pair. Legacy
  (pre-migration) accounts fall back to the old unsalted-hash `pin` field
  via the same callable until login-time migration moves it.
- **Server-side game fan-out.** Match history sync to linked players is a
  Firestore trigger (`onGameCreated`), not a client write — the client no
  longer writes cross-user `matches` docs, and rules deny it outright. The
  trigger reads each player's `firebaseId`, dedupes, and copies the game into
  every linked user's match history (host included), keyed by game id so it's
  idempotent.
- **Game-code import for non-friends.** Players who aren't friends (or don't
  want to link) can still share a game's short room code; the other person
  enters it to pull the game into their own match history via a direct,
  owner-only write. No friendship or rules changes needed for this path.
- **Legacy-user onboarding gate.** Any account where the profile is missing or
  incomplete (`username` empty, no PIN, or `onboardingComplete` false) is
  routed back into the same 4-step onboarding wizard, pre-filled, to complete
  only what's missing. Anonymous sessions bypass the gate; offline launches
  fail open to `authenticated` so the gate can't lock out a user who's offline.
- **Account-deletion cleanup.** Deleting an account triggers server-side
  cleanup (`onUserDeleted`) of the user's own data and social-graph
  references — their profile, friend list, friendship edges pointing at them,
  friend requests, and blocks of them. Games and other players' match
  histories persist untouched.

## Security model

- **Private, salted PIN hashes behind a friends-only, rate-limited callable.**
  PIN hashes live in an owner-only, function-readable subdocument; the
  `validatePin` callable is the only path to compare a submission, requires
  caller/target to already be friends, and locks out after 5 failures for
  15 minutes.
- **Firestore rules enforce the entire social graph.** Friend requests,
  friendships, and blocks are all governed by rules using deterministic
  document ids — the client can't create, accept, or bypass these states
  outside what rules allow.
- **Blocking is bidirectional in effect.** A block removes the friendship both
  ways, hides both users from each other's search, and is designed to fail
  closed; the underlying block doc is one-directional but the enforced
  behavior isn't.
- **Cross-user writes only happen via trigger, never the client.** Match
  history fan-out to linked players is written exclusively by the
  `onGameCreated` Cloud Function; rules deny any client-side cross-user
  `matches` write.
- **Accepted residual risks:**
  - *Users-list wire read:* the `users` collection remains list-readable to
    any signed-in user at the Firestore wire level, so a raw-SDK client could
    still find a blocked user by querying `friendCode` directly, even though
    the official app's callable hides them. Request-create denial and edge
    gating still hold regardless.
  - *Block-status wire leak:* a blocked user's client sees "request sent" or
    "not found" rather than an explicit block message, but a rules denial
    still surfaces as a raw `permission-denied` at the wire level — a
    technically savvy blocked user could infer they've been blocked by
    inspecting error codes. Accepted at this threat model.
