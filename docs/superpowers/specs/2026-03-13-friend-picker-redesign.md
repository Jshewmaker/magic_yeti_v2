# Friend Picker Redesign — Design Spec

## Problem

The friend picker on the customize player page (`_FriendSelectionSection`) has UX and visual issues:

1. **Looks like an afterthought** — A horizontal row of `ActionChip`s crammed above the player name field with no section header or context for what it does.
2. **No visual hierarchy** — Friend chips blend in with the commander search UI. No profile pictures, no sense of a proper list.
3. **Disconnected linked state** — Once a friend is PIN-verified, a green text row appears that looks unrelated to the chips that triggered it.
4. **Missing context** — No explanation of why you'd select a friend. Users choosing between "select a friend" and "type a name manually" have no visual cue that these are the two paths.

The underlying bloc logic (`SelectFriend`, `ClearFriend`, `ValidatePin` in `PlayerCustomizationBloc`) is mostly correct. One handler needs a minor fix: `_onSelectFriend` currently resets `pinValidated: false`, which is incompatible with the new dispatch-after-validation flow (see Section 2). The PIN dialog control flow changes from fire-and-close to await-and-react.

## Approach

**Replace `_FriendSelectionSection` with a dedicated, vertically scrolling friend list section.** Keep all existing bloc events and state fields unchanged. Update the PIN dialog to await validation results. Update the name field to show a linked badge and become read-only when a friend is selected.

## Design

### 1. Friend Section Layout

A section titled **"Select a Friend"** (using existing `l10n.selectFriendLabel`) positioned above the player name field in the `CustomScrollView`. Contains a constrained-height (~160px, roughly 3 items visible) vertically scrolling list of friend tiles.

Each friend tile is a row:
- Circular profile picture (36px radius) — uses `NetworkImage` from `friend.profilePictureUrl` when `friend.profilePictureUrl.isNotEmpty`, otherwise falls back to a first-letter `CircleAvatar` with `AppColors.tertiary` background
- Username text in `AppColors.white`
- When this friend is selected and PIN-verified: a trailing checkmark icon in `AppColors.green` and a border highlight in `AppColors.tertiary`

When no friend is selected, the player name field below is editable as normal — this is the "manual entry" path.

When a friend is selected and PIN-verified:
- The friend's tile shows the highlight/checkmark
- The player name field becomes read-only, populated with the friend's username
- A small `Icons.link` icon in `AppColors.green` appears as a prefix on the name field
- A "Clear" `TextButton` (using existing `l10n.clearButtonText`) in `AppColors.neutral60` appears next to the section header, allowing the user to deselect and return to manual entry

The section is visible when either:
- `FriendBloc` state is `FriendsLoaded` with a non-empty list, OR
- A friend is already selected and PIN-validated (so the selected highlight persists even if friend state reloads)

If neither condition is met, the section is hidden and the name field works exactly as it does today.

### 2. PIN Verification Flow

Tapping a friend tile opens a PIN dialog — same modal `AlertDialog` pattern used elsewhere in the app:
- Dark theme (`AppColors.surface` background)
- Title: uses existing `l10n.verifyFriendTitle(friend.username)`
- Subtitle: uses existing `l10n.enterPinPrompt`
- 4-digit numeric input field, center-aligned, large letter spacing
- Cancel (`l10n.cancelTextButton`) and Verify (`l10n.verifyButtonText`) buttons

**Control flow change from current code:** The current implementation dispatches `SelectFriend` + `ValidatePin` simultaneously, then immediately closes the dialog without waiting for the result. The new flow:

1. User enters PIN and taps Verify
2. Dialog dispatches `ValidatePin` only (not `SelectFriend` yet)
3. Dialog uses a `BlocListener<PlayerCustomizationBloc, PlayerCustomizationState>` to react to state changes:
   - If `pinValidated` becomes `true`: dispatch `SelectFriend`, close dialog, populate name field
   - If `pinError` is non-empty: show error text on PIN field, dialog stays open for retry
4. Cancel closes dialog with no state changes

This ensures `SelectFriend` is only dispatched after successful PIN validation, which means tapping a different friend while one is already selected won't clear the previous selection until the new PIN is verified.

**Bloc handler fix required:** The `_onSelectFriend` handler currently resets `pinValidated: false` (line 136 in `player_customization_bloc.dart`). Under the new flow, `SelectFriend` is dispatched after PIN validation succeeds, so resetting `pinValidated` would break the `_save()` method which checks `state.pinValidated`. Fix: change `_onSelectFriend` to emit `pinValidated: true` instead of `false`, since it's now only called after a successful PIN check.

The `_onValidatePin` handler does not need changes — it only sets `pinValidated` and `pinError`. The dialog is responsible for dispatching `SelectFriend` after observing `pinValidated: true`.

**Temporary state concern:** `ValidatePin` needs to know which friend's PIN to check (`friendUserId`), but `SelectFriend` hasn't been dispatched yet. The `ValidatePin` event already accepts `friendUserId` as a parameter, so the dialog passes `friend.userId` directly — no dependency on `state.selectedFriend`.

### 3. Architecture & Data Flow

**No new blocs, events, states, or files.** One minor bloc handler fix plus presentation changes:

| File | Changes |
|------|---------|
| `lib/player/view/customize_player_page.dart` | Replace `_FriendSelectionSection` widget with redesigned `_FriendSection` containing vertical list, section header with conditional Clear button, and reworked PIN dialog with `BlocListener` |
| `lib/player/view/widgets/player_name_row.dart` | Add new `isLinkedToFriend` parameter (default `false`). When `true`, show `Icons.link` prefix icon in `AppColors.green` instead of the default `Icons.edit`. The existing `isReadOnly` parameter continues to control `readOnly` on the `TextField`. |
| `lib/player/view/bloc/player_customization_bloc.dart` | Change `_onSelectFriend` to emit `pinValidated: true` instead of `false` |

**Unchanged files:**
- `lib/player/view/bloc/player_customization_event.dart` — All events stay as-is
- `lib/player/view/bloc/player_customization_state.dart` — All state fields stay as-is
- `lib/friends_list/friends_list/bloc/friend_list_bloc.dart` — Already created in `CustomizePlayerPage.build()` with `LoadFriends`

The `_save()` method is unchanged — it already reads `state.selectedFriend` and `state.pinValidated` to determine `firebaseId`.

### 4. UI Styling

Follows the existing app dark theme:

- **Section header:** `l10n.selectFriendLabel` text in `AppColors.neutral60`, 14px, left-aligned. "Clear" button in `AppColors.neutral60` appears on the trailing side when a friend is selected and validated.
- **Friend tiles:** `AppColors.surface` background, rounded corners (12px), horizontal padding matching other sections (`AppSpacing.xlg`). Row layout: profile picture + username. Vertical spacing of 8px between tiles.
- **Selected tile:** `AppColors.tertiary` border (2px), trailing `Icons.check_circle` in `AppColors.green`.
- **List container:** Max height ~160px, `ClipRRect` with rounded corners, inner `ListView` uses independent `ClampingScrollPhysics` so it scrolls within its constrained height without interfering with the outer `CustomScrollView`. This is wrapped in a `SliverToBoxAdapter` in the outer scroll view.
- **Name field linked state:** `Icons.link` prefix icon in `AppColors.green` (controlled by `isLinkedToFriend` parameter), `readOnly: true` on the `TextField` (controlled by existing `isReadOnly` parameter).

### 5. Localization

All UI strings use existing l10n keys — no new ARB entries needed:
- `l10n.selectFriendLabel` — "Select a friend"
- `l10n.clearButtonText` — "Clear"
- `l10n.verifyFriendTitle(name)` — "Verify {name}"
- `l10n.enterPinPrompt` — "Enter their 4-digit PIN to confirm identity."
- `l10n.cancelTextButton` — "Cancel"
- `l10n.verifyButtonText` — "Verify"
- PIN error text ("Incorrect PIN") comes from `state.pinError` in the bloc, not from l10n (pre-existing pattern, not changing)

**No longer used by this feature:** `l10n.linkedToFriend` — the current green "Linked to [name]" text row is replaced by tile highlighting + checkmark. The key remains in the ARB files (may be used elsewhere or in the future) but is no longer referenced in `_FriendSection`.

### 6. Edge Cases

- **No friends:** Section hidden entirely. Name field works as today.
- **Friend has empty profile picture:** `friend.profilePictureUrl` is a required non-nullable `String`. When `friend.profilePictureUrl.isEmpty`, show a first-letter `CircleAvatar` with `AppColors.tertiary` background using `friend.username[0].toUpperCase()`.
- **Friend has no PIN set:** PIN dialog still shows. If the friend's stored PIN hash is empty/null, `validatePin` will return false. This is an existing edge case — the friend must have set a PIN during onboarding for this to work. No change needed since onboarding now guarantees a PIN.
- **Tapping a different friend while one is already selected:** Opens PIN dialog for the new friend. Since `SelectFriend` is only dispatched after successful PIN validation, the previous selection remains intact if the user cancels the dialog. If the new PIN is verified, `SelectFriend` is dispatched with the new friend, replacing the previous selection.
- **Clearing selection mid-customization:** `ClearFriend` event dispatched. Name field becomes editable again, cleared to empty. User can type a new name manually.

## Files to Modify

| File | Changes |
|------|---------|
| `lib/player/view/customize_player_page.dart` | Replace `_FriendSelectionSection` with `_FriendSection` |
| `lib/player/view/widgets/player_name_row.dart` | Add `isLinkedToFriend` parameter, swap prefix icon when true |
| `lib/player/view/bloc/player_customization_bloc.dart` | Change `_onSelectFriend` to emit `pinValidated: true` |

## Out of Scope

- Extracting friend logic into a separate bloc (not needed — only 3 events, tightly coupled to save)
- Loading friend's preferred commanders (future feature)
- Friend search/filter within the picker
- Animated transitions between selected/unselected states
