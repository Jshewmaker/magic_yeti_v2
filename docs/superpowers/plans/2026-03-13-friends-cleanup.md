# Friends Feature Cleanup Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix friend request bugs (duplicates, self-friending, missing guards), add relationship-aware search, upgrade to elevated card UI, and fix navigation/refresh issues.

**Architecture:** Repository-level guards in `FirebaseDatabaseRepository` prevent invalid friend requests. New enums (`FriendRequestResult`, `RelationshipStatus`) drive UI state. A shared `FriendCard` widget ensures consistent styling across all friend screens.

**Tech Stack:** Flutter, BLoC, Cloud Firestore, GoRouter, app_ui package (AppColors)

**Spec:** `docs/superpowers/specs/2026-03-13-friends-cleanup-design.md`

---

## Chunk 1: Repository Layer — Enums and Guards

### Task 1: Add FriendRequestResult and RelationshipStatus enums

**Files:**
- Create: `packages/firebase_database_repository/lib/models/friend_request_result.dart`
- Create: `packages/firebase_database_repository/lib/models/relationship_status.dart`
- Modify: `packages/firebase_database_repository/lib/models/models.dart`

- [ ] **Step 1: Create FriendRequestResult enum**

```dart
// packages/firebase_database_repository/lib/models/friend_request_result.dart

/// Result of attempting to send a friend request.
enum FriendRequestResult {
  /// Request was sent successfully.
  sent,

  /// Both users had pending requests — auto-accepted as friends.
  autoAccepted,

  /// Users are already friends.
  alreadyFriends,

  /// A pending request already exists.
  alreadyPending,

  /// Cannot send a friend request to yourself.
  self,
}
```

- [ ] **Step 2: Create RelationshipStatus enum**

```dart
// packages/firebase_database_repository/lib/models/relationship_status.dart

/// The relationship between two users.
enum RelationshipStatus {
  /// No relationship exists.
  none,

  /// Users are friends.
  friends,

  /// Current user sent a pending request to the other user.
  pendingSent,

  /// Other user sent a pending request to the current user.
  pendingReceived,

  /// Same user (self).
  self,
}
```

- [ ] **Step 3: Export new enums from models barrel**

Add to `packages/firebase_database_repository/lib/models/models.dart`:
```dart
export 'friend_request_result.dart';
export 'relationship_status.dart';
```

- [ ] **Step 4: Commit**

```bash
git add packages/firebase_database_repository/lib/models/
git commit -m "feat: add FriendRequestResult and RelationshipStatus enums"
```

---

### Task 2: Add checkRelationshipStatus to repository

**Files:**
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart`

- [ ] **Step 1: Add checkRelationshipStatus method**

Add after `searchByFriendCode` method (after line 575):

```dart
/// Checks the relationship status between two users.
///
/// Returns [RelationshipStatus] indicating the current state:
/// self, friends, pendingSent, pendingReceived, or none.
Future<RelationshipStatus> checkRelationshipStatus(
  String currentUserId,
  String otherUserId,
) async {
  if (currentUserId == otherUserId) return RelationshipStatus.self;

  // Check if already friends
  final friendDoc = await _firebase
      .collection('friends')
      .doc(currentUserId)
      .collection('friendList')
      .doc(otherUserId)
      .get();
  if (friendDoc.exists) return RelationshipStatus.friends;

  // Check if current user sent a pending request
  final sentRequest = await _friendCollection
      .where('senderId', isEqualTo: currentUserId)
      .where('receiverId', isEqualTo: otherUserId)
      .where('status', isEqualTo: 'pending')
      .limit(1)
      .get();
  if (sentRequest.docs.isNotEmpty) return RelationshipStatus.pendingSent;

  // Check if other user sent a pending request
  final receivedRequest = await _friendCollection
      .where('senderId', isEqualTo: otherUserId)
      .where('receiverId', isEqualTo: currentUserId)
      .where('status', isEqualTo: 'pending')
      .limit(1)
      .get();
  if (receivedRequest.docs.isNotEmpty) {
    return RelationshipStatus.pendingReceived;
  }

  return RelationshipStatus.none;
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd packages/firebase_database_repository && dart analyze`

- [ ] **Step 3: Commit**

```bash
git add packages/firebase_database_repository/lib/src/firebase_database_repository.dart
git commit -m "feat: add checkRelationshipStatus to repository"
```

---

### Task 3: Add guards to addFriendRequest

**Files:**
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart`

- [ ] **Step 1: Update addFriendRequest return type and add guards**

Replace the existing `addFriendRequest` method (lines 331-351) with:

```dart
/// Adds a friend request with guards against duplicates, self-requests,
/// and existing friendships.
///
/// Returns [FriendRequestResult] indicating what happened:
/// - [FriendRequestResult.sent] — request created
/// - [FriendRequestResult.autoAccepted] — mutual request, now friends
/// - [FriendRequestResult.alreadyFriends] — already friends
/// - [FriendRequestResult.alreadyPending] — request already exists
/// - [FriendRequestResult.self] — cannot add yourself
Future<FriendRequestResult> addFriendRequest(
  String senderId,
  String senderName,
  String receiverId,
) async {
  // Guard: self-request
  if (senderId == receiverId) return FriendRequestResult.self;

  // Guard: already friends
  final friendDoc = await _firebase
      .collection('friends')
      .doc(senderId)
      .collection('friendList')
      .doc(receiverId)
      .get();
  if (friendDoc.exists) return FriendRequestResult.alreadyFriends;

  // Guard: pending request already sent
  final existingSent = await _friendCollection
      .where('senderId', isEqualTo: senderId)
      .where('receiverId', isEqualTo: receiverId)
      .where('status', isEqualTo: 'pending')
      .limit(1)
      .get();
  if (existingSent.docs.isNotEmpty) {
    return FriendRequestResult.alreadyPending;
  }

  // Guard: reverse request exists — auto-accept
  final reverseRequest = await _friendCollection
      .where('senderId', isEqualTo: receiverId)
      .where('receiverId', isEqualTo: senderId)
      .where('status', isEqualTo: 'pending')
      .limit(1)
      .get();
  if (reverseRequest.docs.isNotEmpty) {
    final reverseDoc = reverseRequest.docs.first;
    final reverseModel = FriendRequestModel.fromJson(
      reverseDoc.data()! as Map<String, dynamic>,
    );
    await acceptFriendRequest(reverseModel, senderId);
    return FriendRequestResult.autoAccepted;
  }

  // All clear — create the request
  final newRequestRef = _friendCollection.doc();
  final documentId = newRequestRef.id;
  await newRequestRef.set({
    'id': documentId,
    'senderId': senderId,
    'senderName': senderName,
    'receiverId': receiverId,
    'status': 'pending',
    'timestamp': FieldValue.serverTimestamp(),
  });
  return FriendRequestResult.sent;
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd packages/firebase_database_repository && dart analyze`

- [ ] **Step 3: Commit**

```bash
git add packages/firebase_database_repository/lib/src/firebase_database_repository.dart
git commit -m "feat: add guards to addFriendRequest (dedup, self, auto-accept)"
```

---

## Chunk 2: Search Bloc — Relationship-Aware Search

### Task 4: Update SearchBloc events and state for relationship status

**Files:**
- Modify: `lib/friends_list/search_user/bloc/search_event.dart`
- Modify: `lib/friends_list/search_user/bloc/search_state.dart`
- Modify: `lib/friends_list/search_user/bloc/search_bloc.dart`

- [ ] **Step 1: Add currentUserId to SearchByFriendCode event**

Replace the `SearchByFriendCode` class in `search_event.dart` (lines 10-16):

```dart
class SearchByFriendCode extends SearchEvent {
  const SearchByFriendCode(this.friendCode, this.currentUserId);
  final String friendCode;
  final String currentUserId;

  @override
  List<Object> get props => [friendCode, currentUserId];
}
```

- [ ] **Step 2: Add RelationshipStatus to SearchLoaded state and add FriendRequestResult to FriendRequestSent**

Replace the `SearchLoaded` and `FriendRequestSent` classes in `search_state.dart` (lines 14-22):

```dart
class SearchLoaded extends SearchState {
  const SearchLoaded(this.users, this.relationshipStatus);
  final List<UserProfileModel> users;
  final RelationshipStatus relationshipStatus;

  @override
  List<Object> get props => [users, relationshipStatus];
}

class FriendRequestSent extends SearchState {
  const FriendRequestSent(this.result, this.users);
  final FriendRequestResult result;
  final List<UserProfileModel> users;

  @override
  List<Object> get props => [result, users];
}
```

- [ ] **Step 3: Update SearchBloc handlers**

Replace the entire bloc body in `search_bloc.dart` (lines 24-65):

```dart
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required this.repository}) : super(SearchInitial()) {
    on<SearchByFriendCode>(_onSearchByFriendCode);
    on<AddFriendRequest>(_onAddFriendRequest);
  }
  final FirebaseDatabaseRepository repository;

  Future<void> _onSearchByFriendCode(
    SearchByFriendCode event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      final user = await repository.searchByFriendCode(event.friendCode);
      if (user != null) {
        final status = await repository.checkRelationshipStatus(
          event.currentUserId,
          user.id,
        );
        emit(SearchLoaded([user], status));
      } else {
        emit(const SearchLoaded([], RelationshipStatus.none));
      }
    } catch (e) {
      emit(SearchError('Failed to search by friend code: $e'));
    }
  }

  Future<void> _onAddFriendRequest(
    AddFriendRequest event,
    Emitter<SearchState> emit,
  ) async {
    // Preserve current users from state for re-display
    final currentUsers = state is SearchLoaded
        ? (state as SearchLoaded).users
        : <UserProfileModel>[];

    try {
      final result = await repository.addFriendRequest(
        event.senderId,
        event.senderName,
        event.receiverId,
      );
      emit(FriendRequestSent(result, currentUsers));
    } catch (e) {
      emit(SearchError('Failed to add friend request: $e'));
    }
  }
```

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze lib/friends_list/search_user/`

- [ ] **Step 5: Commit**

```bash
git add lib/friends_list/search_user/bloc/
git commit -m "feat: add relationship-aware search with status in SearchLoaded"
```

---

### Task 5: Update SearchUserPage UI for relationship states and elevated cards

**Files:**
- Modify: `lib/friends_list/search_user/search_user_page.dart`

- [ ] **Step 1: Fix back button navigation and scaffold background**

In `search_user_page.dart`, remove the unused `import 'package:magic_yeti/home/home_page.dart';` (line 8) since we're replacing `context.go(HomePage.routeName)` with `context.pop()`.

Then change the `Scaffold` and back button (lines 23-38):

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.quaternary,
        title: Text(
          context.l10n.findFriendsTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.onSurfaceVariant,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocProvider(
        create: (context) => SearchBloc(
          repository: context.read<FirebaseDatabaseRepository>(),
        ),
        child: const SearchUserForm(),
      ),
    );
  }
```

- [ ] **Step 2: Update SearchUserForm to pass currentUserId and style the input**

Replace the `SearchUserFormState.build` method (lines 52-125). Keep the existing `dispose()` method (lines 127-131) unchanged:

```dart
  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AppBloc>().state.user.id;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: context.l10n.friendCodeSearchHint,
              labelStyle: const TextStyle(color: AppColors.neutral60),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neutral60),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.tertiary),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.neutral60,
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.read<SearchBloc>().add(
                      SearchByFriendCode(value, currentUserId),
                    );
              }
            },
          ),
        ),
        Expanded(
          child: BlocConsumer<SearchBloc, SearchState>(
            listener: (context, state) {
              if (state is FriendRequestSent) {
                final message = switch (state.result) {
                  FriendRequestResult.sent => context
                      .l10n.friendRequestSentMessage,
                  FriendRequestResult.autoAccepted =>
                    'You are now friends!',
                  FriendRequestResult.alreadyFriends =>
                    'Already friends',
                  FriendRequestResult.alreadyPending =>
                    'Request already pending',
                  FriendRequestResult.self =>
                    'Cannot add yourself',
                };
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: state.result ==
                                FriendRequestResult.sent ||
                            state.result ==
                                FriendRequestResult.autoAccepted
                        ? AppColors.green
                        : AppColors.neutral60,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is SearchLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is FriendRequestSent) {
                // Show updated card with new status
                if (state.users.isEmpty) {
                  return const SizedBox.shrink();
                }
                final status = switch (state.result) {
                  FriendRequestResult.sent =>
                    RelationshipStatus.pendingSent,
                  FriendRequestResult.autoAccepted =>
                    RelationshipStatus.friends,
                  FriendRequestResult.alreadyFriends =>
                    RelationshipStatus.friends,
                  FriendRequestResult.alreadyPending =>
                    RelationshipStatus.pendingSent,
                  FriendRequestResult.self =>
                    RelationshipStatus.self,
                };
                return _SearchResultCard(
                  user: state.users.first,
                  status: status,
                );
              } else if (state is SearchLoaded) {
                if (state.users.isEmpty) {
                  return Center(
                    child: Text(
                      context.l10n.noUserFoundMessage,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return _SearchResultCard(
                  user: state.users.first,
                  status: state.relationshipStatus,
                );
              } else if (state is SearchError) {
                return Center(
                  child: Text(
                    'Error: ${state.message}',
                    style: const TextStyle(
                      color: AppColors.red,
                    ),
                  ),
                );
              } else {
                return Center(
                  child: Text(
                    context.l10n.friendCodeSearchPrompt,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 3: Replace _SearchResultCard with relationship-aware elevated card**

Replace the `_SearchResultCard` class (lines 134-175):

```dart
class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.user,
    required this.status,
  });

  final UserProfileModel user;
  final RelationshipStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.tertiary,
              child: Text(
                (user.username ?? '?').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    user.friendCode ?? '',
                    style: const TextStyle(
                      color: AppColors.neutral60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _buildTrailing(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    switch (status) {
      case RelationshipStatus.none:
        return FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.background,
          ),
          onPressed: () {
            final appBloc = context.read<AppBloc>();
            context.read<SearchBloc>().add(
                  AddFriendRequest(
                    appBloc.state.user.id,
                    appBloc.state.user.name ?? '',
                    user.id,
                  ),
                );
          },
          child: Text(context.l10n.addFriendButtonText),
        );
      case RelationshipStatus.pendingSent:
        return Text(
          'Pending',
          style: TextStyle(
            color: AppColors.neutral60,
            fontStyle: FontStyle.italic,
          ),
        );
      case RelationshipStatus.pendingReceived:
        return FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.background,
          ),
          onPressed: () {
            final appBloc = context.read<AppBloc>();
            context.read<SearchBloc>().add(
                  AddFriendRequest(
                    appBloc.state.user.id,
                    appBloc.state.user.name ?? '',
                    user.id,
                  ),
                );
          },
          child: const Text('Accept'),
        );
      case RelationshipStatus.friends:
        return const Text(
          '✓ Friends',
          style: TextStyle(color: AppColors.green),
        );
      case RelationshipStatus.self:
        return Text(
          'This is you',
          style: TextStyle(
            color: AppColors.neutral60,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }
}
```

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze lib/friends_list/search_user/`

- [ ] **Step 5: Commit**

```bash
git add lib/friends_list/search_user/
git commit -m "feat: relationship-aware search results with elevated card UI"
```

---

## Chunk 3: Friend Request Bloc Fixes

### Task 6: Fix FriendRequestBloc — wrong userId bug and in-memory filtering

**Files:**
- Modify: `lib/friends_list/requests/bloc/friend_request_event.dart`
- Modify: `lib/friends_list/requests/bloc/friend_request_bloc.dart`

- [ ] **Step 1: Add userId to DeclineFriendRequest event**

Replace `DeclineFriendRequest` in `friend_request_event.dart` (lines 38-44):

```dart
class DeclineFriendRequest extends FriendRequestEvent {
  const DeclineFriendRequest(this.request, this.userId);
  final FriendRequestModel request;
  final String userId;

  @override
  List<Object> get props => [request, userId];
}
```

- [ ] **Step 2: Fix bloc handlers to use in-memory filtering**

Replace `_onAcceptFriendRequest` and `_onDeclineFriendRequest` in `friend_request_bloc.dart` (lines 38-60):

```dart
  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<FriendRequestState> emit,
  ) async {
    try {
      await repository.acceptFriendRequest(event.request, event.userId);
      // Remove accepted request from in-memory list
      if (state is FriendRequestLoaded) {
        final updated = (state as FriendRequestLoaded)
            .requests
            .where((r) => r.id != event.request.id)
            .toList();
        emit(FriendRequestLoaded(updated));
      }
    } catch (e) {
      emit(const FriendRequestError('Failed to accept friend request'));
    }
  }

  Future<void> _onDeclineFriendRequest(
    DeclineFriendRequest event,
    Emitter<FriendRequestState> emit,
  ) async {
    try {
      await repository.declineFriendRequest(event.request.id);
      // Remove declined request from in-memory list
      if (state is FriendRequestLoaded) {
        final updated = (state as FriendRequestLoaded)
            .requests
            .where((r) => r.id != event.request.id)
            .toList();
        emit(FriendRequestLoaded(updated));
      }
    } catch (e) {
      emit(const FriendRequestError('Failed to decline friend request'));
    }
  }
```

- [ ] **Step 3: Update FriendRequestsPage to pass userId to DeclineFriendRequest**

In `friend_request_page.dart`, update the decline button onPressed (line 114-117):

```dart
                      onPressed: () {
                        final userId =
                            context.read<AppBloc>().state.user.id;
                        context.read<FriendRequestBloc>().add(
                              DeclineFriendRequest(request, userId),
                            );
                      },
```

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze lib/friends_list/requests/`

- [ ] **Step 5: Commit**

```bash
git add lib/friends_list/requests/
git commit -m "fix: FriendRequestBloc uses correct userId, in-memory state filtering"
```

---

### Task 7: Fix FriendBloc — in-memory removal

**Files:**
- Modify: `lib/friends_list/friends_list/bloc/friend_list_bloc.dart`

- [ ] **Step 1: Update _onRemoveFriend to filter in-memory**

Replace `_onRemoveFriend` in `friend_list_bloc.dart` (lines 43-53):

```dart
  Future<void> _onRemoveFriend(
    RemoveFriend event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await repository.removeFriend(event.userId, event.friendId);
      // Remove friend from in-memory list
      if (state is FriendsLoaded) {
        final updated = (state as FriendsLoaded)
            .friends
            .where((f) => f.userId != event.friendId)
            .toList();
        emit(FriendsLoaded(updated));
      }
    } catch (e) {
      emit(FriendsError('Failed to remove friend: $e'));
    }
  }
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/friends_list/friends_list/bloc/`

- [ ] **Step 3: Commit**

```bash
git add lib/friends_list/friends_list/bloc/friend_list_bloc.dart
git commit -m "fix: FriendBloc filters removed friend from in-memory state"
```

---

## Chunk 4: UI Polish — Elevated Cards, Scaffold Cleanup, Navigation

### Task 8: Create shared FriendCard widget

**Files:**
- Create: `lib/friends_list/widgets/friend_card.dart`

- [ ] **Step 1: Create the shared card widget**

```dart
// lib/friends_list/widgets/friend_card.dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// A styled card for displaying friend-related items.
///
/// Used across friends list, friend requests, and search results
/// for consistent elevated card styling.
class FriendCard extends StatelessWidget {
  const FriendCard({
    required this.initial,
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String initial;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.tertiary,
              child: Text(
                initial.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.neutral60,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/friends_list/widgets/friend_card.dart
git commit -m "feat: add shared FriendCard widget"
```

---

### Task 9: Update FriendsListPage — scaffold, navigation, badge

**Files:**
- Modify: `lib/friends_list/friends_list_page.dart`

- [ ] **Step 1: Update FriendsListPage with background, push navigation, and request badge**

Replace the entire file:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list/friends_list.dart';
import 'package:magic_yeti/friends_list/requests/friend_request_page.dart';
import 'package:magic_yeti/friends_list/search_user/search_user_page.dart';
import 'package:magic_yeti/l10n/l10n.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});
  factory FriendsListPage.pageBuilder(_, __) {
    return const FriendsListPage(key: Key('friends_list_page'));
  }

  static const routeName = 'friendsListPage';
  static const routePath = '/friendsListPage';

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  int _requestCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRequestCount();
  }

  Future<void> _loadRequestCount() async {
    final userId = context.read<AppBloc>().state.user.id;
    final db = context.read<FirebaseDatabaseRepository>();
    try {
      final requests = await db.getFriendRequests(userId);
      if (mounted) {
        setState(() => _requestCount = requests.length);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.quaternary,
          iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
          title: Text(
            l10n.friendsTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.friendsTitle),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.friendRequestsTitle),
                    if (_requestCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_requestCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            indicatorColor: AppColors.tertiary,
            labelColor: AppColors.onSurfaceVariant,
            unselectedLabelColor: AppColors.neutral60,
          ),
        ),
        body: const TabBarView(
          children: [
            FriendsList(),
            FriendRequestsPage(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          foregroundColor: AppColors.white,
          backgroundColor: AppColors.tertiary,
          onPressed: () => context.push(SearchUserPage.routePath),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/friends_list/friends_list_page.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/friends_list/friends_list_page.dart
git commit -m "feat: FriendsListPage with background, push nav, request badge"
```

---

### Task 10: Update FriendsList — remove nested Scaffold, elevated cards

**Files:**
- Modify: `lib/friends_list/friends_list/friends_list.dart`

- [ ] **Step 1: Remove nested Scaffold and use FriendCard**

Replace the entire file:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';
import 'package:magic_yeti/friends_list/widgets/friend_card.dart';

class FriendsList extends StatelessWidget {
  const FriendsList({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user.id;
    return BlocProvider(
      create: (context) => FriendBloc(
        repository: context.read<FirebaseDatabaseRepository>(),
      )..add(LoadFriends(userId)),
      child: const FriendsListView(),
    );
  }
}

class FriendsListView extends StatelessWidget {
  const FriendsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user.id;
    return BlocBuilder<FriendBloc, FriendState>(
      builder: (context, state) {
        if (state is FriendsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FriendsLoaded) {
          if (state.friends.isEmpty) {
            return const Center(
              child: Text(
                'No friends found',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: state.friends.length,
            itemBuilder: (context, index) {
              final friend = state.friends[index];
              return FriendCard(
                initial: friend.username.isNotEmpty
                    ? friend.username[0]
                    : '?',
                title: friend.username,
                subtitle: friend.friendCode,
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.neutral60,
                  ),
                  onPressed: () =>
                      _confirmRemoveFriend(context, friend, userId),
                ),
              );
            },
          );
        } else if (state is FriendsError) {
          return const Center(
            child: Text(
              'Failed to load friends',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          );
        }
        return const Center(
          child: Text(
            'No friends found',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        );
      },
    );
  }

  void _confirmRemoveFriend(
    BuildContext context,
    FriendModel friend,
    String userId,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Remove Friend',
            style: TextStyle(color: AppColors.white),
          ),
          content: Text(
            'Are you sure you want to remove ${friend.username}?',
            style: const TextStyle(color: AppColors.neutral60),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.neutral60),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Remove',
                style: TextStyle(color: AppColors.red),
              ),
              onPressed: () {
                context
                    .read<FriendBloc>()
                    .add(RemoveFriend(userId, friend.userId));
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/friends_list/friends_list/`

- [ ] **Step 3: Commit**

```bash
git add lib/friends_list/friends_list/friends_list.dart
git commit -m "feat: FriendsList with elevated cards, remove nested Scaffold"
```

---

### Task 11: Update FriendRequestsPage — remove nested Scaffold, elevated cards

**Files:**
- Modify: `lib/friends_list/requests/friend_request_page.dart`

- [ ] **Step 1: Remove nested Scaffold and use FriendCard with styled action buttons**

Replace the entire file:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
import 'package:magic_yeti/friends_list/widgets/friend_card.dart';

class FriendRequestsPage extends StatelessWidget {
  const FriendRequestsPage({super.key});

  factory FriendRequestsPage.pageBuilder(_, __) {
    return const FriendRequestsPage(key: Key('friend_requests_page'));
  }

  static const routeName = 'friendRequests';
  static const routePath = '/friendRequests';

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user.id;
    return BlocProvider(
      create: (context) => FriendRequestBloc(
        repository: context.read<FirebaseDatabaseRepository>(),
      )..add(LoadFriendRequests(userId)),
      child: const FriendRequestView(),
    );
  }
}

class FriendRequestView extends StatelessWidget {
  const FriendRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendRequestBloc, FriendRequestState>(
      builder: (context, state) {
        if (state is FriendRequestLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FriendRequestLoaded) {
          if (state.requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending requests',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: state.requests.length,
            itemBuilder: (context, index) {
              final request = state.requests[index];
              return FriendCard(
                initial: request.senderName.isNotEmpty
                    ? request.senderName[0]
                    : '?',
                title: request.senderName,
                subtitle: 'Wants to be your friend',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Icons.check,
                      color: AppColors.green,
                      onPressed: () {
                        final userId =
                            context.read<AppBloc>().state.user.id;
                        context.read<FriendRequestBloc>().add(
                              AcceptFriendRequest(request, userId),
                            );
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.close,
                      color: AppColors.red,
                      onPressed: () {
                        final userId =
                            context.read<AppBloc>().state.user.id;
                        context.read<FriendRequestBloc>().add(
                              DeclineFriendRequest(request, userId),
                            );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        } else if (state is FriendRequestError) {
          return Center(
            child: Text(
              'Failed to load requests: ${state.message}',
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/friends_list/requests/`

- [ ] **Step 3: Commit**

```bash
git add lib/friends_list/requests/
git commit -m "feat: FriendRequestsPage with elevated cards, tinted action buttons"
```

---

## Chunk 5: PIN Dialog Fix and Final Cleanup

### Task 12: Fix PIN setup dialog with Cancel/Save buttons

**Files:**
- Modify: `lib/home/home_page.dart`

- [ ] **Step 1: Update _showPinSetupDialog with proper buttons and validation**

Replace the `_showPinSetupDialog` method (lines 72-121):

```dart
  void _showPinSetupDialog() {
    final pinController = TextEditingController();
    final db = context.read<FirebaseDatabaseRepository>();
    final userId = context.read<AppBloc>().state.user.id;
    final l10n = context.l10n;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                l10n.setYourPinTitle,
                style: const TextStyle(color: AppColors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.setYourPinDescription,
                    style: const TextStyle(color: AppColors.neutral60),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      color: AppColors.white,
                    ),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neutral60),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.tertiary),
                      ),
                      counterText: '',
                      errorText: pinController.text.isNotEmpty &&
                              pinController.text.length < 4
                          ? 'PIN must be 4 digits'
                          : null,
                      errorStyle: const TextStyle(color: AppColors.red),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    l10n.cancelTextButton,
                    style: const TextStyle(color: AppColors.neutral60),
                  ),
                ),
                FilledButton(
                  onPressed: pinController.text.length == 4
                      ? () async {
                          await db.setPin(userId, pinController.text);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        }
                      : null,
                  child: Text(l10n.savePinButtonText),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => pinController.dispose());
  }
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/home/home_page.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/home/home_page.dart
git commit -m "fix: PIN setup dialog with Cancel/Save buttons and validation"
```

---

### Task 13: Remove unused flutter/widgets.dart import from friends_list_page

**Files:**
- Modify: `lib/friends_list/friends_list_page.dart`

- [ ] **Step 1: Check for unused imports and lint errors**

Run: `flutter analyze lib/friends_list/`

Fix any remaining lint issues.

- [ ] **Step 2: Commit if changes needed**

```bash
git add lib/friends_list/
git commit -m "chore: fix lint warnings in friends_list"
```

---

### Task 14: Create Firestore composite indexes

**Files:**
- Note: This is a Firebase console task, not a code change

- [ ] **Step 1: Document required indexes**

The following compound queries require Firestore composite indexes:

1. `friendRequests` collection:
   - Fields: `senderId` (ASC) + `receiverId` (ASC) + `status` (ASC)

If using `firestore.indexes.json`, add:
```json
{
  "indexes": [
    {
      "collectionGroup": "friendRequests",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "senderId", "order": "ASCENDING" },
        { "fieldPath": "receiverId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" }
      ]
    }
  ]
}
```

Note: Firestore will auto-prompt to create these indexes when the queries are first run in development. Click the link in the error message to create them automatically.

- [ ] **Step 2: Test the app to trigger index creation**

Run the app, search for a friend code, and send a request. If a missing index error appears, click the link in the error to create it.

---

### Task 15: Full integration verification

- [ ] **Step 1: Run full analysis**

Run: `flutter analyze`

- [ ] **Step 2: Manual test checklist**

1. Search for your own friend code → should show "This is you"
2. Search for a friend's code → should show "Add" button
3. Send a friend request → card should update to "Pending", SnackBar appears
4. Search same code again → should show "Pending"
5. Accept a request on receiver's device → request disappears from list
6. Decline a request → request disappears from list
7. View friends list → elevated cards with avatars
8. Remove a friend → confirm dialog appears, friend removed from list
9. PIN setup dialog → Cancel dismisses, Save disabled until 4 digits
10. Back button from search → returns to friends list (not home)
