# Player Owner + Friend Selector Redesign — Design Spec

Supersedes: `2026-03-13-friend-picker-redesign.md` (the tile-list implementation that
spec produced is the current code being replaced here — its "friend search/filter"
non-goal is explicitly reversed below now that scale is a real concern).

## Problem

The friend picker on `CustomizePlayerPage` (`_FriendSection` in
`lib/player/view/customize_player_page.dart`) has four issues:

1. **Doesn't scale.** Friends render as tiles in a `ListView` capped at a 160px
   max height ([customize_player_page.dart:288-289](../../../lib/player/view/customize_player_page.dart)).
   Fine for a handful of friends, unusable for a long list.
2. **The account owner isn't a selectable option.** `isAccountOwner` is inferred once,
   in `initState`, from `context.read<PlayerBloc>().state.player.firebaseId != null`
   — a bare non-null check, not an equality check against the signed-in user. Since
   every newly-created player seat starts with `firebaseId: null`
   ([game_bloc.dart:83-100](../../../lib/game/bloc/game_bloc.dart)), there is today no
   path in this screen for the owner to explicitly link their own seat. (The only
   existing "is this seat mine" picker lives on the *game-over* screen —
   `_AccountOwnerDropdown` in `lib/life_counter/view/game_over_page.dart` — which is
   a different flow this spec doesn't touch.)
3. **Reopening an already-linked seat loses the link state, and can silently corrupt it.**
   `PlayerCustomizationBloc` is recreated fresh every time the page opens, so
   `selectedFriend`/`pinValidated` always start unset regardless of the player's
   persisted `firebaseId`. Combined with issue 2's bare non-null check, reopening a
   *friend*-linked seat to tweak the commander and hitting Save can silently
   reassign that seat's `firebaseId` to the current owner, clobbering the friend
   link — because `_save()` falls back to `isAccountOwner` whenever
   `selectedFriend` is null.
4. **Name auto-fill/lock is inconsistent and incomplete.** A *fresh* friend selection
   already sets `nameController.text = friend.username` and
   [player_identity_panel.dart:48](../../../lib/player/view/widgets/player_identity_panel.dart)
   already sets `readOnly: isLinked`. But `isLinked` only checks
   `selectedFriend != null && pinValidated` — it ignores `isAccountOwner` entirely, so
   the owner's name is never locked to anything. And because of issue 3, even the
   friend case's lock doesn't survive reopening the page.

Separately, the PIN verification dialog (`_showPinDialog`) has two independent bugs
that need fixing since this change already touches its trigger point:

5. **No loading state.** `_onValidatePin` never emits an in-flight state, so the
   Verify button has nothing to key a spinner off while the async call is running,
   and nothing prevents a double-submit.
6. **Small-device keyboard overlap.** The `AlertDialog`'s content isn't scrollable,
   so on a small phone the keyboard can push the Verify button out of the reachable
   area.

## Approach

Replace the tile list with a single `DropdownMenu<String?>` (Material 3, part of
`flutter/material.dart` — no new dependency) with `enableFilter: true` for
type-to-search. Entries, in order: **Not linked** (sentinel/default), **Me**, then
friends alphabetically. The dropdown's value *is* the resulting `firebaseId` for
that seat (`null` for unlinked, the current user's id for "Me", `friend.userId` for
a friend), which keeps the save-path logic almost unchanged.

Fix the rehydration bug at its root: derive the real link state from
`player.firebaseId` compared against the signed-in user's id and the loaded friend
list, instead of a bare non-null check. Extend the name-lock behavior
(auto-fill + `readOnly`) to cover the owner case, which requires fetching the
current user's `UserProfileModel.username` into the bloc (the auth-layer `User` on
`AppBloc` has no `username` field — only the Firestore profile does).

Fix the two PIN dialog bugs as incremental changes to the same dialog, not a
redesign of it.

## Design

### 1. Picker Widget

- `DropdownMenu<String?>` replaces `_FriendSection`'s `ListView.separated` +
  `_FriendTile`. `dropdownMenuEntries`:
  - `DropdownMenuEntry(value: null, label: <"Not linked">)`
  - `DropdownMenuEntry(value: currentUserId, label: <"Me">)`
  - one entry per friend, `value: friend.userId`, `label: friend.username`,
    sorted alphabetically by username
- `enableFilter: true` (and `enableSearch: true`) gives type-to-filter across
  however many friends exist, with no custom search plumbing.
- The separate "Clear" `TextButton` is deleted — picking "Not linked" is the new
  way to unlink, consistent with how every other option in the same control works.
- `_FriendTile` is deleted entirely.
- Section visibility: today the whole section hides when there are no friends and
  nothing is linked ([customize_player_page.dart:248](../../../lib/player/view/customize_player_page.dart)).
  Since "Me" is always a valid option for a signed-in, non-anonymous user regardless
  of friend count, that guard is removed — the section (and dropdown) always
  renders for non-anonymous users. The existing anonymous-user placeholder copy is
  unchanged.

### 2. Link State & Rehydration

On `initState`, replace the bare `firebaseId != null` check with:

- `player.firebaseId == currentUserId` → confirmed **Me**. No PIN.
- `player.firebaseId` matches a friend in the loaded `FriendBloc` state → confirmed
  **that friend**, treated as already PIN-validated. Re-opening a page for a seat
  that's already linked to a friend must **not** re-prompt for that friend's PIN —
  PIN entry is required only when *establishing* a new link, not every time the
  screen reopens on an existing one. (This is scoped per-seat: linking that same
  friend to a *different* seat for the first time still requires the PIN. A
  cross-seat "trusted this session" cache was considered and explicitly rejected as
  unneeded scope — no real flow links the same friend to two seats at once.)
- Otherwise → **unlinked**, name freely editable (today's default behavior).

Because the confirmed state now actually reflects what's persisted, saving after
just tweaking a commander can no longer silently reassign or drop an existing link
— this is the fix for problem 3.

Selecting a new dropdown entry:
- **Not linked** → clears the link, unlocks the name, blanks it (matches today's
  Clear button exactly).
- **Me** → confirms immediately, no PIN, locks the name to the owner's username.
- **A friend** → opens the existing PIN dialog (trigger moves from tile `onTap` to
  the dropdown's `onSelected`; the dialog's own await-then-react control flow is
  unchanged). On success: confirms, locks the name to the friend's username. On
  cancel/failure: the dropdown's displayed value reverts to whatever was previously
  confirmed (requires giving the `DropdownMenu` an explicit controller so the
  visible selection can be programmatically reset rather than left on the
  provisional, unconfirmed entry).

### 3. Name Auto-fill & Lock (Owner Case)

`AppBloc.state.user` is the auth-layer `User` model
([user.dart](../../../packages/authentication_client/authentication_client/lib/src/models/user.dart))
— `id`/`email`/`name`/`photo` from the sign-in provider. It has no app `username`.
The app's `username` lives on `UserProfileModel`, fetched via
`FirebaseDatabaseRepository.getUserProfileOnce`/`getUserProfile` — the same call
`ProfileBloc` already makes ([profile_bloc.dart:39-40](../../../lib/profile/bloc/profile_bloc.dart)).
`PlayerCustomizationBloc` already depends on `FirebaseDatabaseRepository`, so this
is a new call on an existing dependency, not a new dependency.

Changes:
- `PlayerCustomizationBloc` fetches the current user's `UserProfileModel` once at
  init (alongside the existing `LibraryRequested` load) and stores `username` in
  state for use as the "Me" entry's locked name.
- `PlayerIdentityPanel`'s `isLinked` computation
  ([player_identity_panel.dart:25-26](../../../lib/player/view/widgets/player_identity_panel.dart))
  changes from `selectedFriend != null && pinValidated` to also treat a confirmed
  `isAccountOwner` as linked, so the name field locks (`readOnly`) for the owner
  case exactly as it already does for friends.
- `_FriendLinkRow`'s "Linked to {username}" copy needs an owner-case label too
  (e.g. "Linked to your account" or reusing the owner's own username — exact copy
  is a small l10n detail, not a design fork).

### 4. PIN Dialog Fixes

**Loading state.** Add `isPinValidating` (bool) to `PlayerCustomizationState`.
`_onValidatePin` emits it `true` before the `await
_firebaseDatabaseRepository.validatePin(...)` call and `false` on every terminal
branch (valid/invalid/lockedOut/notSet/unavailable). The Verify button's
`BlocBuilder` swaps its label for a small `CircularProgressIndicator` while true,
and `onPressed` becomes `null` (blocks double-submit). Cancel and the dropdown
itself are also disabled while validating — without that, cancelling mid-flight
leaves an in-flight `ValidatePin` result with no listener left to react to it once
the dialog is gone (the `BlocListener` reacting to `pinValidated` lives inside the
dialog's own builder).

PIN submission stays gated behind the Verify button's `onPressed` only — this is
already true today (`onChanged` on the PIN field only triggers a local
`setDialogState` rebuild, never dispatches `ValidatePin`); the fix preserves that
and must not introduce any auto-submit-on-4-digits behavior.

**Small-device keyboard overlap.** Add `scrollable: true` to the `AlertDialog`,
which wraps `content` in a `SingleChildScrollView` so the title/PIN field can
scroll while `actions` (Cancel/Verify) stays pinned and reachable at the bottom.
Tighten the dialog's internal spacing somewhat so it needs less room to begin
with. Verify on a small simulated screen size once built.

### 5. Error Handling

- **Friend list still loading, seat already friend-linked:** lock/display the name
  using the player's already-persisted `name` immediately (it was saved as the
  friend's username last time this seat was linked); reconcile against the live
  `FriendModel` once `FriendBloc` finishes loading, in case the friend renamed
  themselves since.
- **Seat linked to a friend no longer in the friends list** (unfriended since):
  don't silently clear a real, persisted link just because the picker can't
  resolve a display entry for it — leave `firebaseId`/name alone unless the user
  actively picks a different dropdown entry.
- **Anonymous users:** unchanged — existing sign-in placeholder copy, no dropdown
  rendered at all.
- **Owner profile fetch fails or is incomplete:** fall back to leaving the name
  field as whatever was already persisted rather than blocking the page; this
  should be rare in practice since the onboarding gate requires a complete profile
  (username + PIN) before reaching gameplay.

### 6. Files to Modify

| File | Changes |
|---|---|
| `lib/player/view/customize_player_page.dart` | Replace tile list with `DropdownMenu<String?>`; delete `_FriendTile` and the Clear `TextButton`; remove the no-friends visibility guard; rewrite `initState` to derive real link state; Verify button gets a loading spinner + disabled state; `AlertDialog` gets `scrollable: true` + tightened spacing; Cancel/dropdown disabled while validating |
| `lib/player/view/bloc/player_customization_bloc.dart` | New handling to fetch the owner's `UserProfileModel` once at init; new/extended handling to resolve real link state (owner/friend/unlinked) from `firebaseId`; `_onValidatePin` emits `isPinValidating` start/stop |
| `lib/player/view/bloc/player_customization_state.dart` | Add `isPinValidating: bool`; add a field for the owner's fetched `username` |
| `lib/player/view/bloc/player_customization_event.dart` | New event(s) for the profile fetch and link-state rehydration |
| `lib/player/view/widgets/player_identity_panel.dart` | `isLinked` includes the owner case; `_FriendLinkRow` gets owner-case copy |
| `lib/l10n/arb/app_en.arb`, `app_es.arb` (+ generated files via `flutter gen-l10n`) | New keys for the "Me" / "Not linked" dropdown entries and the owner-linked label |
| `test/player/player_customization_bloc_test.dart` | Rehydration cases (owner match, friend match, stale/unfriended match, no match); `isPinValidating` transitions; owner-profile fetch |
| Widget tests (new, alongside `test/player/customize_player_page_anonymous_test.dart`) | "Me" visible with zero friends; filter-as-you-type; PIN-gated friend selection; locked name for both owner and friend; spinner during validation; small-screen dialog reachability |

## Out of Scope

- Any change to the game-over screen's separate `_AccountOwnerDropdown`/
  `_PlayerDropdown` — used only as prior art for the dropdown pattern.
- A cross-seat "already validated this friend elsewhere this session" cache —
  explicitly considered and rejected; PIN trust is scoped per-seat.
- The broader friends-autosync mechanism (fan-out to match history) — already
  implemented; this spec is about the picker UI and its bugs, not the sync path.
- Reusable/favorite commander-per-friend suggestions (mentioned in the
  friends-autosync roadmap as a future idea, not part of this change).
