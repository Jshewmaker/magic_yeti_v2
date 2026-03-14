# Friend Picker Redesign — Design Spec

## Problem

The friend picker on the customize player page (`_FriendSelectionSection`) has UX and visual issues:

1. **Looks like an afterthought** — A horizontal row of `ActionChip`s crammed above the player name field with no section header or context for what it does.
2. **No visual hierarchy** — Friend chips blend in with the commander search UI. No profile pictures, no sense of a proper list.
3. **Disconnected linked state** — Once a friend is PIN-verified, a green text row appears that looks unrelated to the chips that triggered it.
4. **Missing context** — No explanation of why you'd select a friend. Users choosing between "select a friend" and "type a name manually" have no visual cue that these are the two paths.

The underlying bloc logic (`SelectFriend`, `ClearFriend`, `ValidatePin` in `PlayerCustomizationBloc`) works correctly. This is a UI-only rework.

## Approach

**Replace `_FriendSelectionSection` with a dedicated, vertically scrolling friend list section.** Keep all existing bloc logic unchanged. Update the name field to show a linked badge and become read-only when a friend is selected.

## Design

### 1. Friend Section Layout

A section titled **"Select a Friend"** positioned above the player name field in the `CustomScrollView`. Contains a constrained-height (~160px, roughly 3 items visible) vertically scrolling list of friend tiles.

Each friend tile is a row:
- Circular profile picture (36px radius) — uses `NetworkImage` from `friend.profilePictureUrl`, falls back to a first-letter `CircleAvatar` if empty
- Username text in `AppColors.white`
- When this friend is selected and PIN-verified: a trailing checkmark icon in `AppColors.green` and a border highlight in `AppColors.tertiary`

When no friend is selected, the player name field below is editable as normal — this is the "manual entry" path.

When a friend is selected and PIN-verified:
- The friend's tile shows the highlight/checkmark
- The player name field becomes read-only, populated with the friend's username
- A small `Icons.link` icon in `AppColors.green` appears as a prefix on the name field
- A "Clear" `TextButton` in `AppColors.neutral60` appears next to the section header, allowing the user to deselect and return to manual entry

The section is only visible when the user has friends loaded (`FriendBloc` state is `FriendsLoaded` with a non-empty list). If no friends exist, the section is hidden and the name field works exactly as it does today.

### 2. PIN Verification Flow

Tapping a friend tile opens a PIN dialog — same modal `AlertDialog` pattern used elsewhere in the app:
- Dark theme (`AppColors.surface` background)
- Title: "Verify [username]"
- 4-digit numeric input field, center-aligned, large letter spacing
- Cancel and Verify buttons

On successful PIN:
- Dialog closes
- Friend tile shows selected state (border + checkmark)
- Name field becomes read-only with friend's username
- `PlayerCustomizationState.selectedFriend` is set, `pinValidated` is `true`

On incorrect PIN:
- Error text on PIN field ("Incorrect PIN")
- Dialog stays open for retry

On cancel:
- Dialog closes, no state change

### 3. Architecture & Data Flow

**No new blocs, events, states, or files.** Changes are contained to existing presentation code:

| File | Changes |
|------|---------|
| `lib/player/view/customize_player_page.dart` | Replace `_FriendSelectionSection` widget with redesigned `_FriendSection` containing vertical list, section header with conditional Clear button, and PIN dialog |
| `lib/player/view/widgets/player_name_row.dart` | Add linked badge (`Icons.link` prefix icon in `AppColors.green`) when `isReadOnly` is true |

**Unchanged files:**
- `lib/player/view/bloc/player_customization_bloc.dart` — All event handlers stay as-is
- `lib/player/view/bloc/player_customization_event.dart` — All events stay as-is
- `lib/player/view/bloc/player_customization_state.dart` — All state fields stay as-is
- `lib/friends_list/friends_list/bloc/friend_list_bloc.dart` — Already created in `CustomizePlayerPage.build()` with `LoadFriends`

The `_save()` method is unchanged — it already reads `state.selectedFriend` and `state.pinValidated` to determine `firebaseId`.

### 4. UI Styling

Follows the existing app dark theme:

- **Section header:** "Select a Friend" text in `AppColors.neutral60`, 14px, left-aligned. "Clear" button in `AppColors.neutral60` appears on the trailing side when a friend is selected.
- **Friend tiles:** `AppColors.surface` background, rounded corners (12px), horizontal padding matching other sections (`AppSpacing.xlg`). Row layout: profile picture + username.
- **Selected tile:** `AppColors.tertiary` border (2px), trailing `Icons.check_circle` in `AppColors.green`.
- **List container:** Max height ~160px, `ClipRRect` with rounded corners, vertical scroll, `NeverScrollableScrollPhysics` disabled (normal scroll).
- **Name field linked state:** `Icons.link` prefix icon in `AppColors.green`, text color slightly dimmed, `readOnly: true` on the `TextField`.

### 5. Edge Cases

- **No friends:** Section hidden entirely. Name field works as today.
- **Friend has no profile picture:** First-letter `CircleAvatar` with `AppColors.tertiary` background.
- **Friend has no PIN set:** PIN dialog still shows. If the friend's stored PIN hash is empty/null, `validatePin` will return false. This is an existing edge case — the friend must have set a PIN during onboarding for this to work. No change needed here since onboarding now guarantees a PIN.
- **Tapping a different friend while one is selected:** Opens PIN dialog for the new friend. If verified, replaces the previous selection. If cancelled, keeps the previous selection.
- **Clearing selection mid-customization:** Name field becomes editable again, cleared to empty. User can type a new name manually.

## Files to Modify

| File | Changes |
|------|---------|
| `lib/player/view/customize_player_page.dart` | Replace `_FriendSelectionSection` with `_FriendSection` |
| `lib/player/view/widgets/player_name_row.dart` | Add linked badge when `isReadOnly` is true |

## Out of Scope

- Extracting friend logic into a separate bloc (not needed — only 3 events, tightly coupled to save)
- Loading friend's preferred commanders (future feature)
- Friend search/filter within the picker
- Animated transitions between selected/unselected states
