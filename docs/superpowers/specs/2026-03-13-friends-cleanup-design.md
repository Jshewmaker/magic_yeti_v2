# Friends Feature Cleanup — Design Spec

## Problem

The friends feature has working building blocks but is not production-ready. Key issues:

1. **Duplicate friend requests** — No guard prevents sending multiple requests to the same person
2. **Self-friending** — Users can search their own code and send themselves a request
3. **Re-requesting existing friends** — No check for existing friendship before sending
4. **No bidirectional auto-accept** — Mutual requests create two pending entries instead of auto-accepting
5. **Text invisible on dark background** — Default text colors blend into the dark theme
6. **PIN setup dialog** — Missing proper confirm/cancel buttons
7. **Navigation broken** — Search page replaces route stack instead of pushing
8. **No post-action refresh** — Accepting/removing doesn't reload the list
9. **No relationship-aware search results** — Always shows "Add" regardless of current status

## Approach

**Repository-Level Guards + UI Polish.** All deduplication and validation logic lives in `FirebaseDatabaseRepository` — the single source of truth. The UI adapts based on what the repository returns. This matches the existing codebase pattern where repositories own business logic and blocs stay thin.

## Design

### 1. Repository Guards — `addFriendRequest()`

Before creating a request, check a hierarchy of conditions:

```
addFriendRequest(senderId, senderName, receiverId) → FriendRequestResult
  1. senderId == receiverId? → return FriendRequestResult.self
  2. Already friends? → query friends/{senderId}/friendList/{receiverId}
     - exists → return FriendRequestResult.alreadyFriends
  3. Pending request sender→receiver? → query friendRequests where
     senderId=sender AND receiverId=receiver AND status=pending
     - exists → return FriendRequestResult.alreadyPending
  4. Pending request receiver→sender? → query friendRequests where
     senderId=receiver AND receiverId=sender AND status=pending
     - exists → query the reverse request document to get its ID,
       then call acceptFriendRequest(reverseRequest, senderId)
       to create bidirectional friendship and delete the request
     - return FriendRequestResult.autoAccepted
  5. All clear → create the request → return FriendRequestResult.sent
```

**Firestore index requirement:** Steps 3 and 4 query `friendRequests` with compound `where` clauses (senderId + receiverId + status). A composite index must be created in Firebase console or `firestore.indexes.json` for this query pattern.

Return type changes from `void` to `FriendRequestResult` enum:
- `sent` — normal success
- `autoAccepted` — both requested each other, now friends
- `alreadyFriends` — no action taken
- `alreadyPending` — no action taken
- `self` — cannot add yourself

No exceptions for expected states. Exceptions reserved for actual failures (network, Firestore errors).

### 2. Relationship Status Check

New repository method:

```
checkRelationshipStatus(currentUserId, otherUserId) → RelationshipStatus

enum RelationshipStatus {
  none,          // no relationship
  friends,       // already friends
  pendingSent,   // current user sent a pending request
  pendingReceived, // other user sent current user a pending request
  self,          // same user
}
```

Queries (in order, short-circuit on first match):
1. `currentUserId == otherUserId` → `self`
2. `friends/{currentUserId}/friendList/{otherUserId}` exists → `friends`
3. `friendRequests` where senderId=current AND receiverId=other AND status=pending → `pendingSent`
4. `friendRequests` where senderId=other AND receiverId=current AND status=pending → `pendingReceived`
5. Otherwise → `none`

Used by `SearchBloc` after finding a user by friend code.

### 3. Search Result States

`SearchBloc` changes:
- `SearchByFriendCode` event now also takes `currentUserId`
- After finding a user, calls `checkRelationshipStatus` to determine the UI state
- `SearchLoaded` state gains a `RelationshipStatus` field

Search result card renders per status:

| Status | Trailing widget |
|--------|----------------|
| `none` | Green filled "Add" button |
| `pendingSent` | Gray italic "Pending" text |
| `pendingReceived` | Green filled "Accept" button |
| `friends` | Green "✓ Friends" text |
| `self` | Gray italic "This is you" text |

After sending a request:
- Show a green success SnackBar: "Friend request sent to {name}!"
- Card updates to show "Pending" state (re-emit `SearchLoaded` with `pendingSent` status)

After auto-accept:
- Show a green success SnackBar: "You and {name} are now friends!"
- Card updates to show "✓ Friends" state

### 4. Elevated Card UI

All friend-related list items use elevated card style:
- Background: `AppColors.surface` (#282A36)
- Border radius: 12px
- Padding: 14px
- Leading: `CircleAvatar` with `AppColors.tertiary` background, white first-letter text
- Title: `AppColors.white` (#E2E8F0)
- Subtitle: `AppColors.neutral60` (#94A3B8)

Friend requests accept/decline buttons:
- Accept: green tinted circle background (rgba green 15% opacity), green check icon
- Decline: red tinted circle background (rgba red 15% opacity), red X icon

Implementation: Create a shared `FriendCard` widget used by friends list, friend requests, and search results to ensure consistent styling.

### 5. Dialog Fixes

**PIN Setup Dialog (home_page.dart):**
- Add "Cancel" TextButton that dismisses dialog
- Add "Save" ElevatedButton (disabled until PIN is exactly 4 digits)
- Validate input length before enabling save
- Show error text if PIN is not 4 digits on submit attempt
- Close dialog on successful save

**Remove Friend Dialog:**
- Style to match app theme (dark background, light text)
- "Cancel" in neutral color, "Remove" in red

### 6. Navigation & Post-Action Refresh Fixes

- **Search page FAB**: Change `context.go(SearchUserPage.routePath)` to `context.push(SearchUserPage.routePath)` in friends_list_page.dart so back button works
- **Search page back button**: Change `context.go(HomePage.routeName)` to `context.pop()` in search_user_page.dart so it returns to friends list instead of home

**Post-action refresh approach:** Remove accepted/declined requests and deleted friends from the in-memory state list directly, avoiding an unnecessary server round-trip.

- **After accepting request**: `FriendRequestBloc` filters the accepted request out of the current `FriendRequestLoaded.requests` list and re-emits
- **After declining request**: Same as accept — filter the declined request out of state and re-emit
- **After removing friend**: `FriendBloc` filters the removed friend out of `FriendsLoaded.friends` and re-emits

**Bug fix — `FriendRequestBloc` uses wrong userId:** The existing `_onAcceptFriendRequest` and `_onDeclineFriendRequest` handlers call `LoadFriendRequests(event.request.senderId)` — this passes the sender's ID but should pass the current user's (receiver's) ID. With the new in-memory filtering approach, this reload call is removed entirely. However, `DeclineFriendRequest` event must gain a `userId` field to match `AcceptFriendRequest`'s signature (needed by the repository's `declineFriendRequest` and for any future reload fallback).

### 7. Scaffold & Layout Cleanup

**Remove nested Scaffolds:** `FriendsList` and `FriendRequestsPage` each wrap their content in their own `Scaffold`, but they are already inside `FriendsListPage`'s Scaffold `TabBarView`. Remove the inner Scaffolds and return `BlocProvider` with content directly.

**Set background on the outer Scaffold:**
- `friends_list_page.dart` — set `backgroundColor: AppColors.background` on the main Scaffold (covers both tabs)
- `search_user_page.dart` — set `backgroundColor: AppColors.background` on its Scaffold

### 8. Request Count Badge

Add a badge to the "Friend Requests" tab showing the count of pending requests:
- `FriendsListPage` needs access to the request count
- Use a `StreamBuilder` or `BlocProvider` at the tab level to get the count
- Show a small circular badge with the count on the tab icon/text
- Hide badge when count is 0

## Files to Modify

| File | Changes |
|------|---------|
| `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` | Add `checkRelationshipStatus()`, update `addFriendRequest()` return type and guards |
| `packages/firebase_database_repository/lib/models/` | Add `FriendRequestResult` and `RelationshipStatus` enums (new file or in existing) |
| `lib/friends_list/search_user/bloc/search_bloc.dart` | Pass `currentUserId`, call `checkRelationshipStatus`, update state |
| `lib/friends_list/search_user/bloc/search_state.dart` | Add `RelationshipStatus` to `SearchLoaded` |
| `lib/friends_list/search_user/bloc/search_event.dart` | Add `currentUserId` to `SearchByFriendCode` |
| `lib/friends_list/search_user/search_user_page.dart` | Render per-status cards, SnackBar feedback, elevated card style |
| `lib/friends_list/friends_list/friends_list.dart` | Elevated card style, scaffold background, post-remove refresh |
| `lib/friends_list/friends_list/bloc/friend_list_bloc.dart` | Re-emit state after remove |
| `lib/friends_list/requests/friend_request_page.dart` | Elevated card style, scaffold background, post-accept/decline refresh |
| `lib/friends_list/requests/bloc/friend_request_bloc.dart` | Fix wrong userId bug, in-memory state filtering after accept/decline |
| `lib/friends_list/requests/bloc/friend_request_event.dart` | Add `userId` to `DeclineFriendRequest` event |
| `lib/friends_list/friends_list_page.dart` | Push instead of go for search, request count badge, set background color |
| `lib/home/home_page.dart` | Fix PIN setup dialog buttons |
| `lib/friends_list/widgets/friend_card.dart` | New shared card widget |

## Out of Scope

- Blocked users feature (deferred)
- Friend request expiration
- Friend limits
- Notification system beyond badge count
- Profile pictures (keeping first-letter avatars for now)
