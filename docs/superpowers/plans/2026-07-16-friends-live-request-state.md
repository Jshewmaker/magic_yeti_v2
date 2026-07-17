# Friends Live Request State — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give friend requests a single live source of truth so a pending request shows as a dot on home and clears itself the moment it is accepted.

**Architecture:** Replace the friends feature's one-shot `.get()` reads with Firestore `.snapshots()` streams, consume them via `emit.forEach` + `restartable()`, and promote `FriendRequestBloc` to the app root so the home dot and the Requests tab badge read one shared instance. Every UI surface then moves because the underlying truth moved — no refresh events, no in-memory bookkeeping.

**Tech Stack:** Flutter, `bloc` ^9.2.0, `bloc_concurrency` ^0.3.0 (already a dependency), `flutter_bloc` ^9.1.1, Cloud Firestore, `bloc_test` ^10.0.0, `mocktail` ^1.0.0, `fake_cloud_firestore` ^3.1.0.

**Spec:** `docs/superpowers/specs/2026-07-16-friends-live-request-state-design.md`

## Global Constraints

- **Lint:** `very_good_analysis` (strict). Run `flutter analyze` before every commit; it must be clean.
- **No new Firestore index or rules deploy.** `watchFriendRequests` must use the exact query `getFriendRequests` uses today (`receiverId ==`, `status == 'pending'`). Any change to the query shape breaks this guarantee and is out of scope.
- **`setState` rule:** blocs for business logic and server state; `setState` only for view ephemera (a toggle, an expand). Do not "fix" any `setState` not named in this plan — the rest were surveyed and are correct as-is.
- **The reference implementation for every stream bloc in this plan is `lib/home/match_history_bloc/match_history_bloc.dart`.** It already solves restartable re-subscription and the empty-userId clear. Follow it rather than inventing a variant.
- **Empty `userId` means "nobody is signed in"** → emit an empty loaded state and return without subscribing. This is the auth gate.
- Do not touch `lib/friends_list/search_user/` or `lib/friends_list/blocked_users/` — already stream-driven or out of scope.

---

### Task 1: Repository streams

Adds `watchFriends` / `watchFriendRequests` alongside the existing `.get()` methods. The `.get()` methods are **not** deleted here — their callers still exist, and deleting them now would break the build. Task 8 removes them once nothing calls them.

**Files:**
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` (add after `getFriendRequests`, ~`:657`)
- Test: `packages/firebase_database_repository/test/src/friend_streams_test.dart` (create)

**Interfaces:**
- Consumes: nothing (first task).
- Produces:
  - `Stream<List<FriendModel>> watchFriends(String userId)`
  - `Stream<List<FriendRequestModel>> watchFriendRequests(String userId)`

- [ ] **Step 1: Write the failing tests**

Create `packages/firebase_database_repository/test/src/friend_streams_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:test/test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseDatabaseRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseDatabaseRepository(firebase: firestore);
  });

  group('watchFriendRequests', () {
    test('emits pending requests addressed to the user', () async {
      await repository.addFriendRequest('bob', 'Bob', null, 'alice');

      final requests = await repository.watchFriendRequests('alice').first;

      expect(requests.map((r) => r.id), ['bob_alice']);
    });

    test('does not emit requests addressed to somebody else', () async {
      await repository.addFriendRequest('bob', 'Bob', null, 'carol');

      final requests = await repository.watchFriendRequests('alice').first;

      expect(requests, isEmpty);
    });

    test('does not emit declined requests', () async {
      await repository.addFriendRequest('bob', 'Bob', null, 'alice');
      await repository.declineFriendRequest('bob_alice');

      final requests = await repository.watchFriendRequests('alice').first;

      expect(requests, isEmpty);
    });

    test('re-emits without the request once it is accepted', () async {
      await repository.addFriendRequest('bob', 'Bob', null, 'alice');
      final request =
          (await repository.watchFriendRequests('alice').first).single;

      // Map to ids so the matcher does not depend on model equality.
      final emissions = repository
          .watchFriendRequests('alice')
          .map((rs) => rs.map((r) => r.id).toList());

      final expectation = expectLater(
        emissions,
        emitsInOrder([
          ['bob_alice'],
          isEmpty,
        ]),
      );

      await repository.acceptFriendRequest(request, 'alice');
      await expectation;
    });
  });

  group('watchFriends', () {
    test('emits an empty list when the user has no friends', () async {
      expect(await repository.watchFriends('alice').first, isEmpty);
    });

    test('emits the friend once a request is accepted', () async {
      await repository.addFriendRequest('bob', 'Bob', null, 'alice');
      final request =
          (await repository.watchFriendRequests('alice').first).single;

      final emissions =
          repository.watchFriends('alice').map((fs) => fs.map((f) => f.userId).toList());

      final expectation = expectLater(
        emissions,
        emitsInOrder([
          isEmpty,
          ['bob'],
        ]),
      );

      await repository.acceptFriendRequest(request, 'alice');
      await expectation;
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd packages/firebase_database_repository && flutter test test/src/friend_streams_test.dart
```

Expected: compile failure — `The method 'watchFriendRequests' isn't defined for the type 'FirebaseDatabaseRepository'`.

- [ ] **Step 3: Implement the streams**

In `packages/firebase_database_repository/lib/src/firebase_database_repository.dart`, insert directly after `getFriendRequests` ends (~`:657`):

```dart
  /// Streams the user's friends, updating in real time.
  Stream<List<FriendModel>> watchFriends(String userId) {
    return _firebase
        .collection('friends')
        .doc(userId)
        .collection('friendList')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Streams the user's incoming pending friend requests, updating in real
  /// time.
  ///
  /// Deliberately the same query as [getFriendRequests] — same equality
  /// filters, same `list` permission — so this needs no new composite index
  /// and no rules change. The only difference is a listener instead of a
  /// one-shot read.
  Stream<List<FriendRequestModel>> watchFriendRequests(String userId) {
    return _friendCollection
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FriendRequestModel.fromJson(
                  doc.data()! as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }
```

Note the asymmetric casts — they are not sloppiness. `_friendCollection` (`:187`) is an untyped `CollectionReference`, so its `doc.data()` needs `! as Map<String, dynamic>` exactly as `getFriendRequests:652` does. The `friends/…/friendList` path builds a typed `CollectionReference<Map<String, dynamic>>`, so `doc.data()` is already typed, matching `getFriends:631`.

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd packages/firebase_database_repository && flutter test test/src/friend_streams_test.dart
```

Expected: all 6 tests PASS.

- [ ] **Step 5: Analyze and commit**

```bash
cd packages/firebase_database_repository && flutter analyze
git add packages/firebase_database_repository/lib/src/firebase_database_repository.dart packages/firebase_database_repository/test/src/friend_streams_test.dart
git commit -m "feat(friends): add watchFriends and watchFriendRequests streams"
```

---

### Task 2: FriendRequestBloc reads the stream

Converts the bloc to `emit.forEach` + `restartable()` and **deletes the success-path in-memory filter**. This is the change that fixes the stale badge. The `LegacyFriendRequestException` recovery is preserved exactly.

**Files:**
- Modify: `lib/friends_list/requests/bloc/friend_request_bloc.dart`
- Test: `test/friends_list/requests/bloc/friend_request_bloc_test.dart` (modify — one existing test asserts the behavior being deleted)

**Interfaces:**
- Consumes: `repository.watchFriendRequests(String userId)` → `Stream<List<FriendRequestModel>>` (Task 1).
- Produces: `FriendRequestBloc` where `LoadFriendRequests(userId)` subscribes (empty `userId` → `FriendRequestLoaded([])`), and `AcceptFriendRequest` / `DeclineFriendRequest` emit **nothing** on success.

- [ ] **Step 1: Replace the existing success test with stream-driven tests**

In `test/friends_list/requests/bloc/friend_request_bloc_test.dart`, **delete** the test named `'removes the accepted request from the in-memory list on success'` (`:76-92`) — it asserts precisely the behavior this task removes. Keep the two failure tests (`:31-74`) untouched; they must still pass.

Add these groups inside `group('FriendRequestBloc', ...)`:

```dart
    group('LoadFriendRequests', () {
      blocTest<FriendRequestBloc, FriendRequestState>(
        'emits [loading, loaded] from the stream',
        setUp: () {
          when(() => repository.watchFriendRequests('alice')).thenAnswer(
            (_) => Stream.value([request]),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriendRequests('alice')),
        expect: () => [
          isA<FriendRequestLoading>(),
          isA<FriendRequestLoaded>()
              .having((s) => s.requests, 'requests', [request]),
        ],
      );

      blocTest<FriendRequestBloc, FriendRequestState>(
        'emits again when the stream emits an update',
        setUp: () {
          when(() => repository.watchFriendRequests('alice')).thenAnswer(
            (_) => Stream.fromIterable([
              [request],
              <FriendRequestModel>[],
            ]),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriendRequests('alice')),
        expect: () => [
          isA<FriendRequestLoading>(),
          isA<FriendRequestLoaded>()
              .having((s) => s.requests, 'requests', [request]),
          isA<FriendRequestLoaded>()
              .having((s) => s.requests, 'requests', isEmpty),
        ],
      );

      blocTest<FriendRequestBloc, FriendRequestState>(
        'emits an empty loaded list and never subscribes when userId is empty',
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriendRequests('')),
        expect: () => [
          isA<FriendRequestLoaded>()
              .having((s) => s.requests, 'requests', isEmpty),
        ],
        verify: (_) {
          verifyNever(() => repository.watchFriendRequests(any()));
        },
      );

      blocTest<FriendRequestBloc, FriendRequestState>(
        'emits [loading, error] when the stream errors',
        setUp: () {
          when(() => repository.watchFriendRequests('alice')).thenAnswer(
            (_) => Stream.error(Exception('boom')),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriendRequests('alice')),
        expect: () => [
          isA<FriendRequestLoading>(),
          isA<FriendRequestError>(),
        ],
      );
    });

    group('AcceptFriendRequest with a live stream', () {
      blocTest<FriendRequestBloc, FriendRequestState>(
        'accepting emits nothing itself — the stream re-emits without the '
        'request, which is what clears the badge',
        setUp: () {
          final controller =
              StreamController<List<FriendRequestModel>>.broadcast();
          when(() => repository.watchFriendRequests('alice'))
              .thenAnswer((_) => controller.stream);
          when(() => repository.acceptFriendRequest(request, 'alice'))
              .thenAnswer((_) async {
            // Stand in for Firestore's latency compensation: the batch delete
            // makes the live query re-emit without the accepted request.
            controller.add(<FriendRequestModel>[]);
          });
          addTearDown(controller.close);
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const LoadFriendRequests('alice'));
          await Future<void>.delayed(Duration.zero);
          bloc.add(AcceptFriendRequest(request, 'alice'));
        },
        expect: () => [
          isA<FriendRequestLoading>(),
          isA<FriendRequestLoaded>()
              .having((s) => s.requests, 'requests', isEmpty),
        ],
      );
    });
```

Add `import 'dart:async';` at the top of the test file for `StreamController`.

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/friends_list/requests/bloc/friend_request_bloc_test.dart
```

Expected: compile failure — `The method 'watchFriendRequests' isn't defined` on the mock's `when(...)` (the bloc does not call it yet).

- [ ] **Step 3: Rewrite the bloc**

Replace the whole of `lib/friends_list/requests/bloc/friend_request_bloc.dart`:

```dart
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';

part 'friend_request_event.dart';
part 'friend_request_state.dart';

/// Bloc implementation for managing friend requests.
///
/// Handles:
/// - Streaming the user's incoming pending friend requests from Firestore.
/// - Accepting and declining friend requests.
///
/// Provided at the app root (see `lib/app/view/app.dart`) so the home
/// indicator and the friends page share one source of truth and open one
/// listener between them.
///
/// @dependencies
/// - FirebaseDatabaseRepository: For interacting with Firestore
/// - Flutter Bloc: For state management
class FriendRequestBloc extends Bloc<FriendRequestEvent, FriendRequestState> {
  FriendRequestBloc({required this.repository})
      : super(FriendRequestLoading()) {
    // restartable: a new LoadFriendRequests cancels the previous Firestore
    // subscription instead of queueing behind it (the handler never
    // completes on its own because the requests stream never closes).
    on<LoadFriendRequests>(_onLoadFriendRequests, transformer: restartable());
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<DeclineFriendRequest>(_onDeclineFriendRequest);
  }
  final FirebaseDatabaseRepository repository;

  Future<void> _onLoadFriendRequests(
    LoadFriendRequests event,
    Emitter<FriendRequestState> emit,
  ) async {
    // An empty userId means "no signed-in user": clear any previous requests
    // and stop listening. Anonymous users have no friend graph, and a
    // listener opened against a non-uid would take a permission error.
    if (event.userId.isEmpty) {
      emit(const FriendRequestLoaded([]));
      return;
    }

    emit(FriendRequestLoading());
    await emit.forEach<List<FriendRequestModel>>(
      repository.watchFriendRequests(event.userId),
      onData: FriendRequestLoaded.new,
      onError: (_, __) =>
          const FriendRequestError('Failed to load friend requests'),
    );
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<FriendRequestState> emit,
  ) async {
    // Captured before the attempt so a legacy-accept failure can restore
    // the list the page was showing — the builder renders the error state
    // as an empty "No pending requests" placeholder, so without recovery
    // the whole list would appear to vanish over one bad request.
    final priorState = state;
    try {
      await repository.acceptFriendRequest(event.request, event.userId);
      // Deliberately no emit on success. acceptFriendRequest ends in a batch
      // delete of the request doc, so the watchFriendRequests query re-emits
      // without it — and Firestore's latency compensation fires the local
      // listener before the server acks, so it is immediate. Maintaining an
      // in-memory copy here is what let the tab badge go stale.
    } on LegacyFriendRequestException {
      emit(const FriendRequestLegacyAcceptError());
      if (priorState is FriendRequestLoaded) {
        emit(priorState);
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
      // No emit, same reasoning as accept: declining flips status to
      // 'declined', which drops the doc out of the pending query.
    } catch (e) {
      emit(const FriendRequestError('Failed to decline friend request'));
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/friends_list/requests/bloc/friend_request_bloc_test.dart
```

Expected: all tests PASS, including the two pre-existing failure tests.

- [ ] **Step 5: Analyze and commit**

```bash
flutter analyze
git add lib/friends_list/requests/bloc/friend_request_bloc.dart test/friends_list/requests/bloc/friend_request_bloc_test.dart
git commit -m "fix(friends): drive FriendRequestBloc from a Firestore stream

The accepted-request badge went stale because the bloc kept a hand-maintained
in-memory copy of the request list. Subscribing to watchFriendRequests makes
the list correct itself when the request doc is deleted."
```

---

### Task 3: FriendBloc reads the stream

Same conversion for the friends list. Both the `RemoveFriend` in-memory filter and the `BlockFriend` re-fetch become redundant — `removeFriend` and `blockUser` each delete the `friendList` edges, so the stream re-emits on its own.

**Files:**
- Modify: `lib/friends_list/friends_list/bloc/friend_list_bloc.dart`
- Test: `test/friends_list/friends_list/bloc/friend_list_bloc_test.dart` (modify — `:49` and `:62` stub/verify `getFriends`)

**Interfaces:**
- Consumes: `repository.watchFriends(String userId)` → `Stream<List<FriendModel>>` (Task 1).
- Produces: `FriendBloc` where `LoadFriends(userId)` subscribes (empty `userId` → `FriendsLoaded([])`), and `RemoveFriend` / `BlockFriend` emit nothing on success.

- [ ] **Step 1: Update the tests**

In `test/friends_list/friends_list/bloc/friend_list_bloc_test.dart`, replace every `repository.getFriends('alice')` stub and verification with `repository.watchFriends('alice')` returning a stream. Add `import 'dart:async';` if not present. Add:

```dart
    group('LoadFriends', () {
      blocTest<FriendBloc, FriendState>(
        'emits [loading, loaded] from the stream',
        setUp: () {
          when(() => repository.watchFriends('alice'))
              .thenAnswer((_) => Stream.value([friend]));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriends('alice')),
        expect: () => [
          isA<FriendsLoading>(),
          isA<FriendsLoaded>().having((s) => s.friends, 'friends', [friend]),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'emits an empty loaded list and never subscribes when userId is empty',
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriends('')),
        expect: () => [
          isA<FriendsLoaded>().having((s) => s.friends, 'friends', isEmpty),
        ],
        verify: (_) {
          verifyNever(() => repository.watchFriends(any()));
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits [loading, error] when the stream errors',
        setUp: () {
          when(() => repository.watchFriends('alice'))
              .thenAnswer((_) => Stream.error(Exception('boom')));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriends('alice')),
        expect: () => [isA<FriendsLoading>(), isA<FriendsError>()],
      );
    });
```

Use whatever `friend` fixture the file already defines; if none exists, add:

```dart
    const friend = FriendModel(
      userId: 'bob',
      username: 'Bob',
      profilePictureUrl: 'http://x/bob.png',
    );
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/friends_list/friends_list/bloc/friend_list_bloc_test.dart
```

Expected: compile failure — `The method 'watchFriends' isn't defined` in the `when(...)` stubs.

- [ ] **Step 3: Rewrite the bloc**

Replace `lib/friends_list/friends_list/bloc/friend_list_bloc.dart`:

```dart
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';

part 'friend_list_event.dart';
part 'friend_list_state.dart';

/// Bloc implementation for managing the user's friends list.
/// It handles streaming the list of friends, removing friends, and blocking.
///
/// Key features:
/// - Subscribes to the repository's friends stream
/// - Removes friends with confirmation
/// - Blocks a friend
///
/// @dependencies
/// - FirebaseDatabaseRepository: For interacting with Firestore
/// - Flutter Bloc: For state management
///
/// @notes
/// - Implements error handling for network issues
class FriendBloc extends Bloc<FriendEvent, FriendState> {
  FriendBloc({required this.repository}) : super(FriendsLoading()) {
    // restartable: see MatchHistoryBloc — emit.forEach never completes on its
    // own, so a re-dispatch must cancel the previous subscription.
    on<LoadFriends>(_onLoadFriends, transformer: restartable());
    on<RemoveFriend>(_onRemoveFriend);
    on<BlockFriend>(_onBlockFriend);
  }

  final FirebaseDatabaseRepository repository;

  Future<void> _onLoadFriends(
    LoadFriends event,
    Emitter<FriendState> emit,
  ) async {
    // An empty userId means "no signed-in user": clear and stop listening.
    if (event.userId.isEmpty) {
      emit(const FriendsLoaded([]));
      return;
    }

    emit(FriendsLoading());
    await emit.forEach<List<FriendModel>>(
      repository.watchFriends(event.userId),
      onData: FriendsLoaded.new,
      onError: (error, _) => FriendsError('Failed to load friends: $error'),
    );
  }

  Future<void> _onRemoveFriend(
    RemoveFriend event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await repository.removeFriend(event.userId, event.friendId);
      // No emit: removeFriend deletes both friendList edges, so the stream
      // re-emits without them.
    } catch (e) {
      emit(FriendsError('Failed to remove friend: $e'));
    }
  }

  Future<void> _onBlockFriend(
    BlockFriend event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await repository.blockUser(
        currentUserId: event.userId,
        target: event.target,
      );
      // No emit: blockUser deletes both friendList edges in its batch, so the
      // stream re-emits without them.
    } on Exception catch (e) {
      emit(FriendsError('Failed to block friend: $e'));
    }
  }
}
```

The `@notes` line claiming *"Ensures real-time updates using Firestore sync"* is dropped from the docstring above — it was false when written, and the replacement text says what the bloc actually does.

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/friends_list/friends_list/
```

Expected: all PASS.

- [ ] **Step 5: Analyze and commit**

```bash
flutter analyze
git add lib/friends_list/friends_list/bloc/friend_list_bloc.dart test/friends_list/friends_list/bloc/friend_list_bloc_test.dart
git commit -m "fix(friends): drive FriendBloc from a Firestore stream

Accepting a request never refreshed the friends list, so a new friend only
appeared after a remount. Subscribing to watchFriends fixes that and makes the
RemoveFriend/BlockFriend bookkeeping redundant."
```

---

### Task 4: Move FriendRequestBloc to the app root

The app-root provider and the page-level provider must swap in one commit — running both would open two listeners on the same query and let the dot and the tab disagree, which is the bug this whole plan exists to kill.

**Files:**
- Modify: `lib/app/view/app.dart` (`:73-81` providers, `:95-97` helper, `:133-141` listener)
- Modify: `lib/friends_list/requests/friend_request_page.dart` (`:20-30` drop provider; `:55` and `:114` l10n)
- Modify: `lib/l10n/arb/app_en.arb`

**Interfaces:**
- Consumes: `FriendRequestBloc` with `LoadFriendRequests(userId)` (Task 2).
- Produces: a `FriendRequestBloc` readable via `context.read/watch` from anywhere below `MultiBlocProvider`, kept subscribed to the signed-in user. Renames the private helper `_historyUserId` → `_signedInUserId`.

- [ ] **Step 1: Add the l10n key**

In `lib/l10n/arb/app_en.arb`, next to `legacyRequestAcceptError`:

```json
  "noPendingRequests": "No pending requests",
  "@noPendingRequests": {
    "description": "Empty state shown on the friend requests tab when the user has no incoming requests"
  },
```

Do **not** add it to `app_es.arb` — that file has no friends keys today (`friendRequestsTitle` is absent from it), and Spanish already falls back to English for this feature. Adding one key here would be inconsistent, not helpful.

- [ ] **Step 2: Regenerate localizations**

```bash
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

Expected: succeeds; `context.l10n.noPendingRequests` resolves.

- [ ] **Step 3: Generalize the helper and provide the bloc app-root**

In `lib/app/view/app.dart`, rename `_historyUserId` (`:95-97`) and broaden its doc:

```dart
/// The user whose data should be streamed: the signed-in user, or nobody
/// (empty id clears the stream and stops listening) for any other auth state.
String _signedInUserId(AppState state) {
  return state.status == AppStatus.authenticated ? state.user.id : '';
}
```

Update its use at `:78` and add the new provider after the `MatchHistoryBloc` provider (`:73-81`):

```dart
          BlocProvider(
            create: (context) => MatchHistoryBloc(
              databaseRepository: context.read<FirebaseDatabaseRepository>(),
            )..add(
                LoadMatchHistory(
                  userId: _signedInUserId(context.read<AppBloc>().state),
                ),
              ),
          ),
          BlocProvider(
            lazy: false,
            create: (context) => FriendRequestBloc(
              repository: context.read<FirebaseDatabaseRepository>(),
            )..add(
                LoadFriendRequests(
                  _signedInUserId(context.read<AppBloc>().state),
                ),
              ),
          ),
```

`lazy: false` is required: the home dot is the first consumer, and a lazy bloc would not subscribe until something read it — which on a cold start is the very screen that needs the answer.

Add the import:

```dart
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
```

- [ ] **Step 4: Re-dispatch on auth change from the existing listener**

Replace the `BlocListener` at `:133-141` — one listener, both blocs, one predicate:

```dart
          // Keep the match history and friend requests subscribed to whoever
          // is signed in; sign-out clears both. Lives at the app root so it
          // holds no matter which screen is visible.
          child: BlocListener<AppBloc, AppState>(
            listenWhen: (previous, current) =>
                _signedInUserId(previous) != _signedInUserId(current),
            listener: (context, state) {
              final userId = _signedInUserId(state);
              context.read<MatchHistoryBloc>().add(
                    LoadMatchHistory(userId: userId),
                  );
              context.read<FriendRequestBloc>().add(
                    LoadFriendRequests(userId),
                  );
            },
            child: child!,
          ),
```

- [ ] **Step 5: Drop the page-level provider and localize the empty states**

In `lib/friends_list/requests/friend_request_page.dart`, replace `build` (`:20-29`):

```dart
  @override
  Widget build(BuildContext context) {
    // The bloc is provided at the app root so this page and the home
    // indicator share one subscription.
    return const FriendRequestView();
  }
```

Then delete the now-unused imports: `firebase_database_repository`, `flutter_bloc`'s `BlocProvider` usage is still needed for `BlocConsumer`, so keep `flutter_bloc`; remove `package:firebase_database_repository/firebase_database_repository.dart` **only if** no other reference remains in the file, and remove the `AppBloc` import only if `:22`'s `userId` read was its sole use (the accept/decline handlers at `:79` and `:91` still read `AppBloc`, so keep it).

Replace both hardcoded strings — `:55` and `:114` — with `context.l10n.noPendingRequests`. Both `Center(child: Text(...))` blocks lose their `const`:

```dart
            return Center(
              child: Text(
                context.l10n.noPendingRequests,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );
```

- [ ] **Step 6: Run the friends and app tests**

```bash
flutter test test/friends_list/ test/app/
```

Expected: PASS. If a widget test constructed `FriendRequestsPage` directly and relied on it providing its own bloc, it must now wrap the widget in a `BlocProvider<FriendRequestBloc>` with a mock — update it rather than reinstating the page provider.

- [ ] **Step 7: Analyze and commit**

```bash
flutter analyze
git add lib/app/view/app.dart lib/friends_list/requests/friend_request_page.dart lib/l10n/arb/app_en.arb
git commit -m "refactor(friends): provide FriendRequestBloc at the app root

One subscription shared by the friends page and (next commit) the home
indicator, so the two surfaces cannot disagree."
```

---

### Task 5: NotificationDot in app_ui

**Files:**
- Create: `packages/app_ui/lib/src/widgets/notification_dot.dart`
- Modify: `packages/app_ui/lib/src/widgets/widgets.dart`
- Test: `packages/app_ui/test/src/widgets/notification_dot_test.dart` (create)

**Interfaces:**
- Consumes: `AppColors` from `app_ui`.
- Produces: `NotificationDot({Key? key, double size = 10})` — a bare red circle, exported from `package:app_ui/app_ui.dart`.

- [ ] **Step 1: Write the failing test**

Create `packages/app_ui/test/src/widgets/notification_dot_test.dart`:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationDot', () {
    testWidgets('renders a red circle at the requested size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NotificationDot(size: 12))),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.red);
      expect(decoration.shape, BoxShape.circle);
      expect(tester.getSize(find.byType(NotificationDot)), const Size(12, 12));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd packages/app_ui && flutter test test/src/widgets/notification_dot_test.dart
```

Expected: compile failure — `Undefined name 'NotificationDot'`.

- [ ] **Step 3: Implement**

Create `packages/app_ui/lib/src/widgets/notification_dot.dart`:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// A small solid dot signalling "something is waiting" without a count.
///
/// Used to mark entry points that lead to unseen items — e.g. the friends
/// icon on home when a friend request is pending. Deliberately countless:
/// the destination shows the number, this only has to be noticed.
class NotificationDot extends StatelessWidget {
  const NotificationDot({super.key, this.size = 10});

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}
```

Add to `packages/app_ui/lib/src/widgets/widgets.dart`, keeping alphabetical order:

```dart
export 'app_shimmer.dart';
export 'hold_to_confirm_button.dart';
export 'notification_dot.dart';
export 'scrollable_column.dart';
export 'skeleton_bone.dart';
export 'stroke_text.dart';
export 'toast.dart';
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd packages/app_ui && flutter test test/src/widgets/notification_dot_test.dart
```

Expected: PASS.

- [ ] **Step 5: Analyze and commit**

```bash
cd packages/app_ui && flutter analyze
git add packages/app_ui/lib/src/widgets/notification_dot.dart packages/app_ui/lib/src/widgets/widgets.dart packages/app_ui/test/src/widgets/notification_dot_test.dart
git commit -m "feat(app_ui): add NotificationDot"
```

---

### Task 6: FriendsListPage reads the bloc and stops being stateful

Deletes `_requestCount` — the field this whole plan is about.

**Files:**
- Modify: `lib/friends_list/friends_list_page.dart`
- Test: `test/friends_list/friends_list_page_test.dart` (create)

**Interfaces:**
- Consumes: app-root `FriendRequestBloc` (Task 4).
- Produces: `FriendsListPage` as a `StatelessWidget`.

- [ ] **Step 1: Write the failing test**

Create `test/friends_list/friends_list_page_test.dart`. The `pumpApp` helper in `test/helpers/pump_app.dart` only wraps a widget in a localized `MaterialApp` — it provides no blocs — so this file builds its own subject, following the shape `test/home/view/home_page_test.dart` uses:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list_page.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_repository/user_repository.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockFriendRequestBloc
    extends MockBloc<FriendRequestEvent, FriendRequestState>
    implements FriendRequestBloc {}

class _MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  late AppBloc appBloc;
  late FriendRequestBloc friendRequestBloc;
  late FriendBloc friendBloc;
  late FirebaseDatabaseRepository databaseRepository;

  final request = FriendRequestModel(
    id: 'bob_alice',
    senderId: 'bob',
    senderName: 'Bob',
    receiverId: 'alice',
    status: 'pending',
    timestamp: DateTime(2024),
  );

  setUp(() {
    appBloc = _MockAppBloc();
    friendRequestBloc = _MockFriendRequestBloc();
    friendBloc = _MockFriendBloc();
    databaseRepository = _MockFirebaseDatabaseRepository();

    when(() => appBloc.state).thenReturn(
      const AppState.authenticated(User(id: 'alice')),
    );
    when(() => friendBloc.state).thenReturn(const FriendsLoaded([]));
  });

  Widget buildSubject() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: databaseRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: appBloc),
            BlocProvider.value(value: friendRequestBloc),
            BlocProvider.value(value: friendBloc),
          ],
          child: const FriendsListPage(),
        ),
      ),
    );
  }

  group('FriendsListPage', () {
    testWidgets('shows the request count on the Requests tab', (tester) async {
      when(() => friendRequestBloc.state)
          .thenReturn(FriendRequestLoaded([request]));

      await tester.pumpWidget(buildSubject());

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows no count when there are no requests', (tester) async {
      when(() => friendRequestBloc.state)
          .thenReturn(const FriendRequestLoaded([]));

      await tester.pumpWidget(buildSubject());

      expect(find.text('0'), findsNothing);
    });

    testWidgets(
        'count clears when the bloc emits an empty list, with no remount '
        '— the original bug', (tester) async {
      whenListen(
        friendRequestBloc,
        Stream<FriendRequestState>.fromIterable([
          const FriendRequestLoaded([]),
        ]),
        initialState: FriendRequestLoaded([request]),
      );

      await tester.pumpWidget(buildSubject());
      expect(find.text('1'), findsOneWidget);

      await tester.pump();
      expect(find.text('1'), findsNothing);
    });
  });
}
```

`AppState.authenticated` and the `User` constructor must match whatever `test/home/view/home_page_test.dart` and the blocked-users page test already use — copy the exact form from one of them rather than guessing; `home_page_test.dart:32` uses `const User(id: 'user-1')`.

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/friends_list/friends_list_page_test.dart
```

Expected: the third test FAILS — the badge still reads `_requestCount` from `initState`, so it never updates.

- [ ] **Step 3: Convert the page**

In `lib/friends_list/friends_list_page.dart`:

1. Change `class FriendsListPage extends StatefulWidget` to `extends StatelessWidget`.
2. Delete `createState` (`:24-25`) and the entire `_FriendsListPageState` preamble — `_requestCount` (`:29`), `initState` (`:31-35`), and `_loadRequestCount` (`:37-46`).
3. Move `build` onto `FriendsListPage` itself.
4. Delete the now-unused imports: `dart:async` (only `unawaited` used it) and `firebase_database_repository` (only `_loadRequestCount` used it). Keep `AppBloc` only if something else in the file reads it — if not, delete that import too.
5. Wrap the Requests tab in a `BlocBuilder` and read the count from the bloc:

```dart
              Tab(
                child: BlocBuilder<FriendRequestBloc, FriendRequestState>(
                  builder: (context, state) {
                    final requestCount = state is FriendRequestLoaded
                        ? state.requests.length
                        : 0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.friendRequestsTitle),
                        if (requestCount > 0) ...[
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
                              '$requestCount',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
```

Any non-`FriendRequestLoaded` state yields `0`, so the badge hides while loading, on error, and during the transient `FriendRequestLegacyAcceptError`. That last one is a known, accepted single-frame flicker: the bloc re-emits `priorState` immediately after (`friend_request_bloc.dart`), so the count returns on the next frame.

Add the import:

```dart
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/friends_list/
```

Expected: all PASS.

- [ ] **Step 5: Analyze and commit**

```bash
flutter analyze
git add lib/friends_list/friends_list_page.dart test/friends_list/friends_list_page_test.dart
git commit -m "fix(friends): read the request count from the bloc, not widget state

_requestCount was fetched once in initState and never invalidated, so the tab
badge stayed frozen after accepting a request. The page no longer needs State
at all."
```

---

### Task 7: The home indicator

**Files:**
- Modify: `lib/home/widgets/section_header.dart` (`:7-25` constructor/fields, `:48-56` the icon button)
- Modify: `lib/home/view/home_page.dart` (`:83-87` tablet, `:128-133` phone)
- Test: `test/home/view/home_page_test.dart` (**extend — this file already exists**)

**Interfaces:**
- Consumes: `NotificationDot` (Task 5); app-root `FriendRequestBloc` (Task 4).
- Produces: `SectionHeader` gains `bool showBadge` (default `false`).

- [ ] **Step 1: Extend the existing home test**

`test/home/view/home_page_test.dart` already has `buildSubject({required bool isPhone})` (`:54`) and `setViewSize` (`:44`). Add the mock class next to the others (`:15-24`):

```dart
class _MockFriendRequestBloc
    extends MockBloc<FriendRequestEvent, FriendRequestState>
    implements FriendRequestBloc {}
```

Declare and construct it alongside the existing mocks (`:27-42`):

```dart
  late FriendRequestBloc friendRequestBloc;
  // ...in setUp:
  friendRequestBloc = _MockFriendRequestBloc();
```

Add it to the `MultiBlocProvider` inside `buildSubject` (`:65-69`):

```dart
            providers: [
              BlocProvider.value(value: appBloc),
              BlocProvider.value(value: matchHistoryBloc),
              BlocProvider.value(value: friendRequestBloc),
            ],
```

Add the fixture next to `authenticatedUser` (`:32`):

```dart
  final pendingRequest = FriendRequestModel(
    id: 'bob_user-1',
    senderId: 'bob',
    senderName: 'Bob',
    receiverId: 'user-1',
    status: 'pending',
    timestamp: DateTime(2024),
  );
```

Then the new group — both layouts, because the dot has two independent call sites and a passing phone test proves nothing about the tablet:

```dart
  group('friend request dot', () {
    for (final isPhone in [true, false]) {
      final layout = isPhone ? 'phone' : 'tablet';

      testWidgets('$layout: shows a dot when a request is pending',
          (tester) async {
        setViewSize(tester, isPhone: isPhone);
        when(() => friendRequestBloc.state)
            .thenReturn(FriendRequestLoaded([pendingRequest]));

        await tester.pumpWidget(buildSubject(isPhone: isPhone));
        await tester.pumpAndSettle();

        expect(find.byType(NotificationDot), findsOneWidget);
      });

      testWidgets('$layout: shows no dot when there are no requests',
          (tester) async {
        setViewSize(tester, isPhone: isPhone);
        when(() => friendRequestBloc.state)
            .thenReturn(const FriendRequestLoaded([]));

        await tester.pumpWidget(buildSubject(isPhone: isPhone));
        await tester.pumpAndSettle();

        expect(find.byType(NotificationDot), findsNothing);
      });

      testWidgets('$layout: shows no dot while the stream is erroring',
          (tester) async {
        setViewSize(tester, isPhone: isPhone);
        when(() => friendRequestBloc.state)
            .thenReturn(const FriendRequestError('boom'));

        await tester.pumpWidget(buildSubject(isPhone: isPhone));
        await tester.pumpAndSettle();

        expect(find.byType(NotificationDot), findsNothing);
      });
    }
  });
```

Add the import for the bloc:

```dart
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
```

`NotificationDot` and `AppColors` both come from the `package:app_ui/app_ui.dart` import already at `:1`.

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/home/view/home_page_test.dart
```

Expected: the first test FAILS — `findsNothing` where one was expected; no dot is rendered anywhere.

- [ ] **Step 3: Add `showBadge` to SectionHeader**

In `lib/home/widgets/section_header.dart`, extend the constructor and fields:

```dart
  const SectionHeader({
    required this.title,
    super.key,
    this.onMorePressed,
    this.icon,
    this.showBadge = false,
  });

  final String title;
  final VoidCallback? onMorePressed;

  /// Optional icon for the trailing action button. When provided, this icon is
  /// always shown (e.g. a friends icon for opening the friends list). When
  /// null, the button shows the user's profile photo, falling back to a
  /// single-person icon.
  final IconData? icon;

  /// Whether to overlay a [NotificationDot] on the trailing action button,
  /// marking unseen items behind it. Only honoured when [icon] is set.
  final bool showBadge;
```

Replace the `icon != null` branch at `:48-56` so the dot overlays the icon:

```dart
            if (icon != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onMorePressed,
                    icon: Icon(
                      icon,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (showBadge)
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: IgnorePointer(child: NotificationDot()),
                    ),
                ],
              )
```

`IgnorePointer` matters — the dot sits over the button's tap target, and without it the most obvious place to tap would be dead.

- [ ] **Step 4: Wire both home layouts**

In `lib/home/view/home_page.dart`, add the import:

```dart
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
```

Add a shared private helper at the bottom of the file:

```dart
/// True when the signed-in user has at least one pending friend request.
///
/// Any non-loaded state (loading, error, the transient legacy-accept error)
/// reads as false: a dot that might be wrong sends the user to a page to find
/// nothing, which is worse than no dot.
bool _hasPendingRequests(FriendRequestState state) =>
    state is FriendRequestLoaded && state.requests.isNotEmpty;
```

Tablet — replace `:83-87`:

```dart
                BlocBuilder<FriendRequestBloc, FriendRequestState>(
                  builder: (context, state) => SectionHeader(
                    title: l10n.matchHistoryTitle,
                    icon: Icons.people,
                    showBadge: _hasPendingRequests(state),
                    onMorePressed: () =>
                        context.push(FriendsListPage.routePath),
                  ),
                ),
```

Phone — replace the `actions` list at `:128-133`:

```dart
          actions: [
            BlocBuilder<FriendRequestBloc, FriendRequestState>(
              builder: (context, state) => Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => context.push(FriendsListPage.routePath),
                    icon: const Icon(Icons.people),
                  ),
                  if (_hasPendingRequests(state))
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: IgnorePointer(child: NotificationDot()),
                    ),
                ],
              ),
            ),
          ],
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/home/
```

Expected: all PASS.

- [ ] **Step 6: Analyze and commit**

```bash
flutter analyze
git add lib/home/widgets/section_header.dart lib/home/view/home_page.dart test/home/view/home_page_test.dart
git commit -m "feat(home): show a dot on the friends icon for pending requests"
```

---

### Task 8: Delete the dead one-shot reads

Nothing calls `getFriends` or `getFriendRequests` after Tasks 2, 3 and 6. Leaving them is leaving the footgun loaded.

**Files:**
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` (delete `:622-636`, `:643-657`)
- Modify: `packages/firebase_database_repository/test/src/friend_request_lifecycle_test.dart` (`:123-127`)

**Interfaces:**
- Consumes: `watchFriendRequests` (Task 1).
- Produces: nothing new — removes `getFriends` and `getFriendRequests` from the public API.

- [ ] **Step 1: Confirm there are no callers left**

```bash
grep -rn "getFriends\|getFriendRequests" lib/ packages/ test/ --include="*.dart" | grep -v "\.g\.dart"
```

Expected: only `packages/firebase_database_repository/test/src/friend_request_lifecycle_test.dart:123-127`, the definitions themselves, and the prose reference in the `blockUser` docstring (`:805`). **If any `lib/` hit remains, stop — an earlier task is incomplete.**

- [ ] **Step 2: Convert the surviving test**

In `friend_request_lifecycle_test.dart`, rewrite the test at `:123`:

```dart
    test('watchFriendRequests still filters to pending only', () async {
      await repository.addFriendRequest('alice', 'Alice', null, 'bob');
      await repository.addFriendRequest('carol', 'Carol', null, 'bob');
      await repository.declineFriendRequest('carol_bob');

      final requests = await repository.watchFriendRequests('bob').first;

      expect(requests.map((r) => r.id), ['alice_bob']);
    });
```

Keep the surrounding assertions in that test's original body if they cover more than the two lines shown at `:123-127`; only the read call and the test name change.

- [ ] **Step 3: Delete the methods**

Remove `getFriends` (`:622-636`) and `getFriendRequests` (`:643-657`) entirely, including their docstrings. In the `blockUser` docstring at `:805`, update the stale prose reference:

```dart
  /// is denied. Declined docs don't need deleting: they're already invisible
  /// to [watchFriendRequests] and permanently suppress re-sends. Rather than
```

- [ ] **Step 4: Run the full suite**

```bash
flutter test
cd packages/firebase_database_repository && flutter test
cd ../app_ui && flutter test
```

Expected: all PASS. A dangling reference to a deleted method surfaces here as a compile error.

- [ ] **Step 5: Analyze and commit**

```bash
flutter analyze
git add packages/firebase_database_repository/
git commit -m "refactor(friends): remove the one-shot getFriends/getFriendRequests reads"
```

---

### Task 9: Move the stats time range into its bloc

Independent of Tasks 1–8 — different feature, its own commit. Included because it is the only other place in `lib/` where domain logic lives in widget `State`.

**Files:**
- Modify: `lib/stats_overview/stats_overview_bloc/stats_overview_bloc.dart`
- Modify: `lib/stats_overview/stats_overview_bloc/stats_overview_event.dart`
- Modify: `lib/stats_overview/stats_overview_bloc/stats_overview_state.dart`
- Modify: `lib/stats_overview/widgets/stats_overview.dart` (`:64-77` `_filterGames`, `:88-92` `_onRangeChanged`)
- Test: `test/stats_overview/stats_overview_bloc/stats_overview_bloc_test.dart`

**Interfaces:**
- Consumes: `StatsTimeRange`, `CompileStatsOverviewData({required String userId, required List<GameModel> games})`.
- Produces: `StatsTimeRangeChanged(StatsTimeRange range)`; `CompileStatsOverviewData` gains no parameters but the bloc now filters internally; the selected range becomes readable from `StatsOverviewState`.

- [ ] **Step 1: Add `range` to the loaded state**

`StatsOverviewState` is a `sealed class` whose variants are `final class`; `StatsOverviewLoaded` already carries `userId` and `games` (the filtered list) plus the 18 computed stats, all as `required` named params. **There is no count field** — the game count is `games.length`.

Add `range` alongside them in `lib/stats_overview/stats_overview_bloc/stats_overview_state.dart`:

```dart
  const StatsOverviewLoaded({
    required this.userId,
    required this.games,
    required this.range,
    // ...the existing 18 stat params, unchanged
  });

  final String userId;
  final List<GameModel> games;

  /// The time range the [games] were filtered to. Owned here rather than by
  /// the widget so the dropdown renders from bloc state.
  final StatsTimeRange range;
```

Add `range` to the `props` list. Keeping it `required` matches the other 20 fields; every site constructing `StatsOverviewLoaded` directly — the bloc, and any test fixture — must now pass `range:`, and the compiler will point at each one.

- [ ] **Step 2: Write the failing tests**

In `test/stats_overview/stats_overview_bloc/stats_overview_bloc_test.dart`:

```dart
    blocTest<StatsOverviewBloc, StatsOverviewState>(
      'defaults to allTime and keeps every game',
      build: buildBloc,
      act: (bloc) => bloc.add(
        CompileStatsOverviewData(userId: 'alice', games: [oldGame, newGame]),
      ),
      expect: () => [
        isA<StatsOverviewLoaded>()
            .having((s) => s.range, 'range', StatsTimeRange.allTime)
            .having((s) => s.games.length, 'games.length', 2),
      ],
    );

    blocTest<StatsOverviewBloc, StatsOverviewState>(
      'StatsTimeRangeChanged re-filters the games already held, without the '
      'caller re-supplying them',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          CompileStatsOverviewData(userId: 'alice', games: [oldGame, newGame]),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const StatsTimeRangeChanged(StatsTimeRange.last30Days));
      },
      skip: 1,
      expect: () => [
        isA<StatsOverviewLoaded>()
            .having((s) => s.range, 'range', StatsTimeRange.last30Days)
            .having((s) => s.games.length, 'games.length', 1),
      ],
    );
```

Fixtures: `oldGame` with `endTime: DateTime(2020)` and `newGame` with an `endTime` inside the last 30 days. Reuse whatever `GameModel` fixture the existing stats tests already build — do not hand-roll a new one; `GameModel` requires a populated `players` list and the 18 stat calculators read it.

- [ ] **Step 3: Run tests to verify they fail**

```bash
flutter test test/stats_overview/stats_overview_bloc/stats_overview_bloc_test.dart
```

Expected: compile failure on two counts — `StatsTimeRangeChanged` is undefined, and every existing `StatsOverviewLoaded(...)` construction now misses the required `range:`. Step 1 deliberately breaks the build; Step 4 restores it. Do not "fix" the constructor errors by giving `range` a default — passing it explicitly at each site is the point.

- [ ] **Step 4: Move the filtering into the bloc**

Add the event:

```dart
/// Re-filters the games already held by the bloc to a new time range.
///
/// The bloc keeps the last compiled game list, so changing the range does not
/// require the caller to re-supply it.
class StatsTimeRangeChanged extends StatsOverviewEvent {
  const StatsTimeRangeChanged(this.range);
  final StatsTimeRange range;

  @override
  List<Object> get props => [range];
}
```

In the bloc, register the handler, hold the inputs, and move `_filterGames` over verbatim from `stats_overview.dart:64-77`:

```dart
    on<StatsTimeRangeChanged>(_onTimeRangeChanged);

  List<GameModel> _allGames = const [];
  String _userId = '';
  StatsTimeRange _range = StatsTimeRange.allTime;

  List<GameModel> _filterGames(List<GameModel> games) {
    if (_range == StatsTimeRange.allTime) {
      return games;
    }
    final now = DateTime.now();
    final cutoff = switch (_range) {
      StatsTimeRange.last12Months => DateTime(now.year - 1, now.month, now.day),
      StatsTimeRange.last6Months => DateTime(now.year, now.month - 6, now.day),
      StatsTimeRange.last3Months => DateTime(now.year, now.month - 3, now.day),
      StatsTimeRange.last30Days => now.subtract(const Duration(days: 30)),
      StatsTimeRange.allTime => now,
    };
    return games.where((game) => game.endTime.isAfter(cutoff)).toList();
  }

  void _onTimeRangeChanged(
    StatsTimeRangeChanged event,
    Emitter<StatsOverviewState> emit,
  ) {
    _range = event.range;
    _emitCompiled(emit);
  }
```

In the existing `CompileStatsOverviewData` handler, store `_allGames = event.games` and `_userId = event.userId`, then run the existing 18-stat computation over `_filterGames(_allGames)` instead of over `event.games`, and include `range: _range` on the emitted `StatsOverviewLoaded`. Extract that computation into `_emitCompiled(emit)` so both handlers share it — do not duplicate it.

- [ ] **Step 5: Strip the widget back to a view**

In `lib/stats_overview/widgets/stats_overview.dart`: delete `_selectedRange`, `_filterGames` (`:64-77`), and `_onRangeChanged`'s `setState` (`:90`). `_compileStats` no longer filters:

```dart
  void _compileStats(List<GameModel> games) {
    context.read<StatsOverviewBloc>().add(
      CompileStatsOverviewData(
        userId: context.read<AppBloc>().state.user.id,
        games: games,
      ),
    );
  }

  void _onRangeChanged(StatsTimeRange? range) {
    if (range == null) return;
    context.read<StatsOverviewBloc>().add(StatsTimeRangeChanged(range));
  }
```

The dropdown's `value` now reads `state.range` inside the existing `BlocBuilder` (`:101`) rather than a local field. The widget stays a `StatefulWidget` — its `initState` (`:55-61`) still seeds the first compile from `MatchHistoryBloc` — but it no longer owns any domain state.

- [ ] **Step 6: Run the tests**

```bash
flutter test test/stats_overview/
```

Expected: all PASS.

- [ ] **Step 7: Analyze and commit**

```bash
flutter analyze
git add lib/stats_overview/ test/stats_overview/
git commit -m "refactor(stats): move time-range filtering into StatsOverviewBloc

The date-cutoff logic lived in the widget's State class and handed the bloc a
pre-filtered list. The range is now bloc state and the filtering is bloc logic."
```

---

## Final verification

- [ ] **Full suite, every package**

```bash
flutter test
cd packages/firebase_database_repository && flutter test && cd ../..
cd packages/app_ui && flutter test && cd ../..
flutter analyze
```

Expected: all green.

- [ ] **Drive the actual bug on a device**

Automated tests cannot prove the Firestore latency-compensation claim this design rests on — `fake_cloud_firestore` and mocked streams both fake exactly the thing in question. Run the app against the real backend and confirm by hand:

```bash
flutter run --flavor development --target lib/main_development.dart
```

1. Send a friend request from a second account.
2. **Home shows the dot without a restart** — this is the live listener working.
3. Open friends; the Requests tab shows the count.
4. Accept.
5. **The tab count clears and the dot disappears immediately, with no navigation** — this is the original bug, and the in-memory filter is gone, so passing means the stream did it.
6. The new friend appears on the Friends tab without a remount.
7. Sign out and back in as the other account; the dot reflects that account, not the previous one.
