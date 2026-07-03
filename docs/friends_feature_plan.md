# Friends List Feature — Implementation Plan

> **⚠️ SUPERSEDED (2026-07-03):** Most items below are already implemented on `main`
> (friend codes, PIN, friend selection on the customize player page, post-game sync,
> onboarding gating). The current design for the remaining hardening & completion work
> lives at [`docs/superpowers/specs/2026-07-03-friends-feature-design.md`](superpowers/specs/2026-07-03-friends-feature-design.md).

## Overview

Enable authenticated users to add friends via a short friend code, manage friend requests, and select friends as players when setting up a game. When a game ends, match history syncs to every authenticated player's profile — not just the host's.

---

## Current State

### What Exists
- **Friend models:** `FriendModel`, `FriendRequestModel` in `firebase_database_repository`
- **Friend BLoCs:** `SearchBloc`, `FriendBloc`, `FriendRequestBloc`
- **Friend UI:** `FriendsListPage` (friends tab + requests tab), `SearchUserPage`, `FriendRequestsPage`
- **Firebase methods:** `addFriendRequest`, `acceptFriendRequest`, `declineFriendRequest`, `removeFriend`, `getFriends`, `getFriendRequests`, `searchUsers`
- **Onboarding:** Page exists with username/firstName/lastName/bio fields, but the `isNewUser` → `onboardingRequired` routing isn't wired up in `AppBloc`

### What's Missing
- Friend code (short unique ID) — search is currently by username/email
- 4-digit numeric PIN per user
- Friend selection on `CustomizePlayerPage`
- Post-game sync to all authenticated players' match histories
- Onboarding trigger from `AppBloc` (the `onboardingRequired` status exists but isn't emitted)

---

## Data Model Changes

### 1. `UserProfileModel` — Add Fields

**File:** `packages/firebase_database_repository/lib/models/user_profile_model.dart`

```dart
class UserProfileModel {
  // existing fields...
  final String? friendCode;  // e.g. "YETI-A3F9" — generated once, immutable
  final String? pin;          // 4-digit numeric string, e.g. "0742"
}
```

**Firebase path:** `users/{userId}/friendCode`, `users/{userId}/pin`

**Friend code format:** `YETI-XXXX` where X is alphanumeric uppercase (A-Z, 0-9). This gives 36^4 = ~1.7M combinations. Generated at account creation, stored in Firestore, indexed for lookup.

### 2. `Player` Model — No Structural Changes

The existing `firebaseId` field on `Player` already handles linking a player slot to an authenticated user. No changes needed.

### 3. Firebase Indexes

Add a Firestore index on `users.friendCode` for efficient friend code lookup.

---

## Implementation Phases

### Phase 1: Friend Code & PIN Infrastructure

#### 1.1 Update `UserProfileModel`
- Add `friendCode` and `pin` fields
- Update `fromJson`/`toJson` serialization
- Run `build_runner` for codegen if using `json_serializable`

#### 1.2 Friend Code Generation
**File:** `packages/firebase_database_repository/lib/src/firebase_database_repository.dart`

Add method:
```dart
Future<String> generateUniqueFriendCode() async {
  // Generate random "YETI-XXXX" code
  // Query Firestore to ensure uniqueness
  // Return the unique code
}
```

Called once during onboarding/profile setup. The code is permanent and never changes.

#### 1.3 Search by Friend Code
**File:** `packages/firebase_database_repository/lib/src/firebase_database_repository.dart`

Add/replace method:
```dart
Future<UserProfileModel?> searchByFriendCode(String code) async {
  // Query users collection where friendCode == code
  // Return matching user profile or null
}
```

Update the existing `SearchBloc` to use friend code search instead of (or in addition to) username/email search.

#### 1.4 PIN Storage
- PIN is set during onboarding (Phase 2)
- Stored as a field on the user profile in Firestore
- PIN is hashed before storage (use a simple hash — this isn't high-security, it's game identity verification)
- Validation method: `Future<bool> validatePin(String userId, String pin)`

> **Security note:** The PIN is a convenience check ("is this really you?"), not a security boundary. Hashing is good practice but the threat model is low — these are friends playing a card game together on one device.

---

### Phase 2: Onboarding Updates

#### 2.1 Fix Onboarding Trigger in `AppBloc`
**File:** `lib/app/bloc/app_bloc.dart`

In `_onUserChanged`, add logic:
```dart
if (event.user != User.anonymous && event.user.isNewUser) {
  emit(state.copyWith(status: AppStatus.onboardingRequired));
  return;
}
```

This ensures new users hit the onboarding flow before reaching the home page.

#### 2.2 Add PIN Field to Onboarding Form
**File:** `lib/onboarding/view/onboarding_form.dart`

Add a 4-digit numeric PIN input field:
- Numeric keyboard only
- 4 digit max length
- Required field (must be set to complete onboarding)
- Show explanation: "This PIN confirms your identity when friends add you to a game"

#### 2.3 Update `OnboardingBloc`
**File:** `lib/onboarding/bloc/onboarding_bloc.dart`

- Add `OnboardingPinChanged` event
- Add `pin` field to state
- On `OnboardingSubmitted`:
  1. Generate friend code via `generateUniqueFriendCode()`
  2. Hash the PIN
  3. Save profile with friendCode + hashedPin
  4. Set `isNewUser = false`

#### 2.4 Add PIN to Profile Page
**File:** `lib/profile/view/profile_page.dart`

- Display the user's friend code prominently (read-only, with copy button)
- Allow PIN change (enter current PIN to set new PIN)
- Show friend code in a shareable format

#### 2.5 Add `Pin` Form Input
**File:** `packages/form_inputs/lib/src/pin.dart`

Create a `Pin` formz input class:
- Valid: exactly 4 numeric digits
- Invalid: empty, non-numeric, wrong length

---

### Phase 3: Friend Search & Request Flow Updates

#### 3.1 Update Search UI
**File:** `lib/friends_list/search_user/search_user_page.dart`

Replace the current search with friend-code-based search:
- Single text field with placeholder "Enter friend code (e.g. YETI-A3F9)"
- Format the input automatically (uppercase, add dash)
- Show matched user profile with "Add Friend" button
- Show "No user found" if code doesn't match

#### 3.2 Update `SearchBloc`
**File:** `lib/friends_list/search_user/bloc/search_bloc.dart`

- Replace `searchUsers(query)` with `searchByFriendCode(code)`
- Keep the request flow: `addFriendRequest(senderId, senderName, receiverId)`

#### 3.3 Friend Request Flow (Unchanged)
The existing accept/decline/pending flow works as-is. No changes needed to:
- `FriendRequestBloc`
- `FriendRequestsPage`
- `FriendModel` / `FriendRequestModel`
- `addFriendRequest` / `acceptFriendRequest` / `declineFriendRequest`

---

### Phase 4: Friend Selection on Customize Player Page

This is the core UX change — letting users pick a friend as a player.

#### 4.1 Update `CustomizePlayerPage` UI
**File:** `lib/player/view/customize_player_page.dart`

Add a "Select Friend" section above or alongside the name input:

```
┌─────────────────────────────────────┐
│  [Select Friend]  or  [Type Name]   │  ← toggle/tabs
│                                      │
│  If "Select Friend":                │
│  ┌──────────────┐                    │
│  │ Friend A     │ ← tap to select   │
│  │ Friend B     │                    │
│  │ Friend C     │                    │
│  └──────────────┘                    │
│                                      │
│  [Enter 4-digit PIN: ____]          │  ← appears after selection
│                                      │
│  Commander: [search/select]         │
│  Partner: [toggle + search]         │
│  [Save]                             │
└─────────────────────────────────────┘
```

**Behavior:**
- Show list of accepted friends (from `FriendBloc`)
- Tapping a friend auto-populates the name field (read-only when friend selected)
- PIN dialog appears — must enter correct PIN to confirm
- Commander/partner selection remains manual
- On save: `firebaseId` is set to the friend's Firebase UID
- A "Clear" button to deselect friend and go back to manual name entry

#### 4.2 Update `PlayerCustomizationBloc`
**File:** `lib/player/view/bloc/player_customization_bloc.dart`

Add events/state:
- `SelectFriendEvent(FriendModel friend)` — sets selected friend
- `ClearFriendEvent` — clears friend selection
- `ValidatePinEvent(String pin)` — validates PIN against friend's stored hash
- State additions: `selectedFriend`, `pinValidated`, `pinError`

#### 4.3 PIN Validation Flow
When a friend is selected:
1. Show PIN input dialog/field
2. Call `firebase_database_repository.validatePin(friendUserId, enteredPin)`
3. If valid: lock in the friend, set `firebaseId`, auto-fill name
4. If invalid: show error, allow retry
5. User can still cancel and type a name manually instead

#### 4.4 Update `PlayerBloc.UpdatePlayerInfoEvent`
**File:** `lib/player/bloc/player_bloc.dart`

The existing event already accepts `firebaseId`. Ensure it passes through correctly when a friend is selected. No structural changes needed — just verify the data flow.

---

### Phase 5: Post-Game Sync

This is the key data flow change — fan out game results to all authenticated players.

#### 5.1 Update `GameBloc` Game Finish Flow
**File:** `lib/game/bloc/game_bloc.dart`

Current flow in `_onGameFinish`:
1. Create `GameModel`
2. Call `saveGameStats(gameModel)` — saves to `games/` collection
3. Save to `users/{hostId}/matches/{gameId}`

New flow:
1. Create `GameModel` (unchanged)
2. Call `saveGameStats(gameModel)` (unchanged)
3. **For each player with a non-null `firebaseId`:**
   - Save to `users/{player.firebaseId}/matches/{gameId}`
   - This includes the host AND any friends linked to player slots

#### 5.2 Update `FirebaseDatabaseRepository.saveGameStats`
**File:** `packages/firebase_database_repository/lib/src/firebase_database_repository.dart`

Modify to accept a list of user IDs to sync to:
```dart
Future<void> saveGameStats(GameModel game, {List<String> playerFirebaseIds = const []}) async {
  // Save to games/ collection (existing)
  // Save to users/{id}/matches/ for EACH id in playerFirebaseIds
}
```

Or add a separate method:
```dart
Future<void> syncGameToPlayers(GameModel game, List<String> firebaseIds) async {
  for (final id in firebaseIds) {
    await _firestore.collection('users').doc(id).collection('matches').doc(game.id).set(game.toJson());
  }
}
```

#### 5.3 Edge Cases
- **Host is always synced** (existing behavior, unchanged)
- **String-only players** (no `firebaseId`) are skipped — no sync target
- **Duplicate firebaseIds** (same user in two slots?) — deduplicate before syncing
- **Game save failure** for one player shouldn't block others — use `Future.wait` with error handling per player

---

### Phase 6: Stats Integration

#### 6.1 Update Stats Queries
**File:** `lib/stats_overview/stats_overview_bloc/stats_overview_bloc.dart`

Currently stats are calculated from the host's match history. Since friends now have their own match history copies, their stats pages will automatically work — no changes needed to the stats calculation logic itself.

#### 6.2 Friend Stats View (Future Enhancement)
This is out of scope for the initial implementation but worth noting: eventually you could view a friend's stats from your friends list. This would require reading `users/{friendId}/matches/` — which is the same data structure already used for the current user's stats.

---

## Firebase Database Schema (Updated)

```
Firestore Root:
├── users/
│   └── {userId}/
│       ├── username: "josh"
│       ├── email: "josh@example.com"
│       ├── firstName: "Josh"
│       ├── lastName: "S"
│       ├── bio: "..."
│       ├── imageUrl: "..."
│       ├── isNewUser: false
│       ├── isAnonymous: false
│       ├── friendCode: "YETI-A3F9"       ← NEW
│       ├── pin: "hashed_pin_value"         ← NEW
│       ├── matches/ (subcollection)
│       │   └── {gameId}/ (GameModel)
│       └── friends/ (subcollection or field)
│
├── games/
│   └── {docId}/ (GameModel)
│
├── friends/
│   └── {userId}/
│       └── {friendId}/ (FriendModel)
│
└── friendRequests/
    └── {requestId}/
        ├── senderId, receiverId, senderName
        ├── status: "pending"
        └── timestamp
```

---

## File Change Summary

| File | Change |
|------|--------|
| `packages/firebase_database_repository/lib/models/user_profile_model.dart` | Add `friendCode`, `pin` fields |
| `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` | Add `generateUniqueFriendCode`, `searchByFriendCode`, `validatePin`, update `saveGameStats` |
| `packages/form_inputs/lib/src/pin.dart` | **New file** — `Pin` formz input |
| `lib/app/bloc/app_bloc.dart` | Wire up `onboardingRequired` status for new users |
| `lib/onboarding/view/onboarding_form.dart` | Add PIN input field |
| `lib/onboarding/bloc/onboarding_bloc.dart` | Add PIN event/state, generate friend code on submit |
| `lib/profile/view/profile_page.dart` | Display friend code, allow PIN change |
| `lib/profile/bloc/profile_bloc.dart` | Add PIN change logic |
| `lib/friends_list/search_user/search_user_page.dart` | Switch to friend code search UI |
| `lib/friends_list/search_user/bloc/search_bloc.dart` | Use `searchByFriendCode` instead of `searchUsers` |
| `lib/player/view/customize_player_page.dart` | Add friend selection UI with PIN verification |
| `lib/player/view/bloc/player_customization_bloc.dart` | Add friend selection + PIN validation events/state |
| `lib/game/bloc/game_bloc.dart` | Fan out game results to all players with `firebaseId` |
| `lib/l10n/arb/app_en.arb` | Add localization strings for new UI elements |
| `lib/l10n/arb/app_es.arb` | Spanish translations |

---

## Implementation Order

```
Phase 1: Friend Code & PIN Infrastructure     (data layer)
  └─ Phase 2: Onboarding Updates              (first user touchpoint)
       └─ Phase 3: Friend Search Updates       (discovery)
            └─ Phase 4: Player Selection       (core feature)
                 └─ Phase 5: Post-Game Sync    (data flow)
                      └─ Phase 6: Stats        (verification & polish)
```

Each phase is independently testable. Phase 1-2 can ship without 3-6, giving existing users friend codes early.

---

## Testing Strategy

- **Unit tests:** BLoC tests for each new/modified bloc (onboarding, player customization, game finish sync)
- **Repository tests:** Mock Firestore for `generateUniqueFriendCode`, `searchByFriendCode`, `validatePin`, `syncGameToPlayers`
- **Widget tests:** Customize player page with friend selection, onboarding form with PIN
- **Integration:** Full flow — sign up → onboarding (get code + PIN) → add friend → create game → select friend → play → game over → verify both players have match in history

---

## Decisions

1. **Friend code format:** `YETI-XXXX` (alphanumeric uppercase, 36^4 = ~1.7M combinations)
2. **PIN hashing:** SHA-256 — sufficient for a game identity check, not a password
3. **Existing users without friend codes:** Generate code automatically on launch, prompt for PIN setup via a banner/dialog
4. **Friend code in `FriendModel`:** Store it on the model — it's immutable once generated, avoids extra reads
