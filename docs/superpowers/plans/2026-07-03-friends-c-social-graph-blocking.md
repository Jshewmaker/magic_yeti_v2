# Friends Plan C: Social Graph & Blocking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the social graph with deterministic request IDs and a full rules lifecycle matrix, ship full blocking (hidden from search, requests refused, unselectable via friendship removal), move friend-code search behind a block-aware callable, and close the trigger-injection debt from the Plan B review.

**Architecture:** Spec phases 4–5 of `docs/superpowers/specs/2026-07-03-friends-feature-design.md` plus the "Plan C must own" list in `docs/superpowers/plans/2026-07-03-friends-INDEX.md`. Friend-request docs move to deterministic IDs (`{senderId}_{receiverId}`) so security rules can check pending/declined/blocked preconditions with `exists()`. Social-graph WRITES stay client-side (batches) secured by rules; the ONLY new callable is `searchByFriendCode` (rules can't filter query results, so block-hiding needs a server lookup). Declining retains the doc (`status: 'declined'`) to power silent re-send suppression. Blocks live at `users/{uid}/blocks/{blockedUid}` (owner-managed; enforced against senders via `exists()` in the request-create rule).

**Tech Stack:** unchanged (firebase-functions v2, `@firebase/rules-unit-testing`, Flutter BLoC, fake_cloud_firestore, mocktail/bloc_test).

## Global Constraints

- **Environment:** rules/emulator suite runs via `npx firebase-tools@14.9.0 emulators:exec --only firestore "npm --prefix functions run test:rules"` from the repo root (plain `firebase` binary broken). ALWAYS pipe flutter output through `tail -5` (bare output kills agent streams). Analyzer gate: no NEW issues vs the ~165 root baseline.
- Deterministic request doc ID is exactly `'{senderId}_{receiverId}'`. CREATE enforces it in rules; UPDATE/DELETE rules are participant-scoped via `resource.data` so legacy random-ID docs remain declinable/cancelable.
- **Named, accepted legacy breakage:** pending requests created before this deploy (random doc IDs) cannot be ACCEPTED once rules tighten (the friendship-edge create rule checks the deterministic path). They CAN be declined. The accept flow maps the rules denial to friendly "ask them to re-send" copy. Record in INDEX.
- Blocking semantics: blocking removes the friendship both ways, deletes/declines pending requests both ways, and writes `users/{me}/blocks/{target}`; blocked users get not-found from search and permission-denied (surfaced as normal "sent") on request create; unblock deletes the block doc only — no auto re-friend.
- Block-status concealment is UI-level only (spec's accepted tradeoff): wire-level `permission-denied` on create is mapped to `FriendRequestResult.sent`.
- `searchByFriendCode` callable: request `{code}`; response `{found: bool, user?: {id, username, imageUrl, friendCode}, relationship?: 'self'|'friends'|'pendingSent'|'pendingReceived'|'none'}`; returns `found: false` when either party blocks the other; requires authenticated non-anonymous caller; normalizes code (trim/uppercase) server-side.
- Trigger hardening (Plan B review debt): `games` create rule requires `request.resource.data.hostId == request.auth.uid`; `onGameCreated` rejects `firebaseId`/`hostId` values containing `/`; malformed-input tests added (non-array `players`, missing `hostId`, slash ids).
- All new user-facing strings in BOTH arb files + `flutter gen-l10n --arb-dir="lib/l10n/arb"`.
- TDD per task; commit per task; current branch `feat/friends-hardening`; no deploys (INDEX gate).

---

### Task 1: Trigger + games-create hardening (Plan B review debt)

**Files:**
- Modify: `functions/src/on-game-created.ts`
- Modify: `firestore.rules` (games block)
- Modify: `functions/test/rules/on-game-created.integration.test.ts`
- Modify: `functions/test/rules/firestore-rules.test.ts`

**Interfaces:**
- Consumes: Plan B's trigger and rules.
- Produces: injection-hardened fan-out; `games` create validated to the caller's uid.

- [ ] **Step 1: Failing tests.** In `on-game-created.integration.test.ts` add:

```typescript
test('ids containing a slash are skipped, others still fan out', async () => {
  await fireWith(
    gameDoc({
      hostId: 'users/alice',
      players: [
        { id: 'p1', firebaseId: 'x/y' },
        { id: 'p2', firebaseId: 'ok-user' },
      ],
    }),
  );
  expect((await db.doc('users/ok-user/matches/g1').get()).exists).toBe(true);
  const all = await db.collectionGroup('matches').get();
  expect(all.size).toBe(1);
});

test('non-array players field writes only the host copy', async () => {
  await fireWith(gameDoc({ players: 'corrupt' }));
  const all = await db.collectionGroup('matches').get();
  expect(all.size).toBe(1);
  expect((await db.doc('users/host/matches/g1').get()).exists).toBe(true);
});

test('missing hostId key with valid players still fans out to players', async () => {
  const data = gameDoc({ players: [{ id: 'p1', firebaseId: 'friend1' }] });
  delete (data as Record<string, unknown>).hostId;
  await fireWith(data);
  expect((await db.doc('users/friend1/matches/g1').get()).exists).toBe(true);
});
```

In `firestore-rules.test.ts`, replace the games create test:

```typescript
  test('signed-in user can create a game they host; foreign hostId denied', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'games/g10'), { hostId: 'alice', roomId: 'AB2C' }),
    );
    await assertFails(
      setDoc(doc(alice(), 'games/g11'), { hostId: 'bob', roomId: 'CD3E' }),
    );
  });
```

- [ ] **Step 2: RED** via emulators:exec (slash test fans out to the hostile path or throws; foreign-hostId create currently allowed).

- [ ] **Step 3: Implement.** In `on-game-created.ts`, extract a helper and use it for both hostId and player ids:

```typescript
function isPlausibleUid(value: unknown): value is string {
  return typeof value === 'string' && value.length > 0 && !value.includes('/');
}
```

Replace the two checks (`typeof game.hostId === 'string' && game.hostId.length > 0` and the player-loop condition) with `isPlausibleUid(...)`, with a comment: a `/` in an id would address a different document path entirely and, under `retry: true`, a thrown batch would starve legitimate recipients for the retry window.

In `firestore.rules`, games block:

```
    match /games/{gameId} {
      allow read: if signedIn();
      // Creator must be the host they claim — the trigger fans the doc out
      // to hostId's match history, so a forged hostId would inject games
      // into another user's history.
      allow create: if signedIn() && request.resource.data.hostId == request.auth.uid;
      allow update, delete: if signedIn() && resource.data.hostId == request.auth.uid;
    }
```

NOTE the client impact check: `GameOverBloc` sets `hostId: event.userId` (the caller) before `saveGameStats` — compliant. `checkIfGameIdExists` only reads. No other client writes `games/`.

- [ ] **Step 4: GREEN** — full emulator suite + `cd functions && npm test`.
- [ ] **Step 5: Commit** — `fix: harden onGameCreated against injected ids; games create requires own hostId`

---

### Task 2: Repository — deterministic request IDs, declined retention, silent suppression

**Files:**
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` (`addFriendRequest`, `declineFriendRequest`; add `friendRequestDocId` static helper)
- Create: `packages/firebase_database_repository/test/src/friend_request_lifecycle_test.dart`

**Interfaces:**
- Consumes: existing `FriendRequestModel`, `FriendRequestResult`, `acceptFriendRequest` (unchanged).
- Produces (Tasks 3, 5, 6 rely on): `static String friendRequestDocId(String senderId, String receiverId) => '${senderId}_$receiverId';` — new requests created AT that doc id with the same field shape as today (`id` field = doc id); `declineFriendRequest(requestId)` now UPDATES `{status: 'declined'}` instead of deleting; `addFriendRequest` returns `FriendRequestResult.sent` silently when a declined own-direction doc exists OR when the create is denied by rules (blocked).

- [ ] **Step 1: Failing tests** (fake_cloud_firestore; no rules in fakes — permission-denied mapping is tested via a thrown `FirebaseException` with a mocked... fake_cloud_firestore can't throw rules errors: assert the try/catch mapping by unit-testing the catch branch is exercised through a `whenCalling`... SKIP wire-level denial here; Task 3's rules tests cover the denial itself, and the catch-mapping is a 3-line `on FirebaseException catch` — verify by code review + the widget flow. State this explicitly in the test file header comment.) Test cases:

```dart
    test('new requests use the deterministic doc id and id field', () async {
      final result =
          await repository.addFriendRequest('alice', 'Alice', 'bob');
      expect(result, FriendRequestResult.sent);
      final doc = await firestore.doc('friendRequests/alice_bob').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['id'], 'alice_bob');
      expect(doc.data()!['status'], 'pending');
      expect(doc.data()!['senderId'], 'alice');
      expect(doc.data()!['receiverId'], 'bob');
    });

    test('re-send onto an existing pending returns alreadyPending', () async {
      await repository.addFriendRequest('alice', 'Alice', 'bob');
      expect(
        await repository.addFriendRequest('alice', 'Alice', 'bob'),
        FriendRequestResult.alreadyPending,
      );
    });

    test('declined doc suppresses re-send silently as sent', () async {
      await repository.addFriendRequest('alice', 'Alice', 'bob');
      await repository.declineFriendRequest('alice_bob');
      final result =
          await repository.addFriendRequest('alice', 'Alice', 'bob');
      expect(result, FriendRequestResult.sent);
      // Still declined — no new pending doc, receiver never sees it again.
      final doc = await firestore.doc('friendRequests/alice_bob').get();
      expect(doc.data()!['status'], 'declined');
    });

    test('decline retains the doc with status declined', () async {
      await repository.addFriendRequest('alice', 'Alice', 'bob');
      await repository.declineFriendRequest('alice_bob');
      final doc = await firestore.doc('friendRequests/alice_bob').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['status'], 'declined');
    });

    test('reverse pending auto-accepts and removes both request docs',
        () async {
      await firestore.collection('users').doc('alice').set({'username': 'a'});
      await firestore.collection('users').doc('bob').set({'username': 'b'});
      await repository.addFriendRequest('bob', 'Bob', 'alice');
      final result =
          await repository.addFriendRequest('alice', 'Alice', 'bob');
      expect(result, FriendRequestResult.autoAccepted);
      expect(
        (await firestore.doc('friends/alice/friendList/bob').get()).exists,
        isTrue,
      );
      expect(
        (await firestore.doc('friends/bob/friendList/alice').get()).exists,
        isTrue,
      );
      expect(
        (await firestore.doc('friendRequests/bob_alice').get()).exists,
        isFalse,
      );
    });

    test('getFriendRequests still filters to pending only', () async {
      await repository.addFriendRequest('alice', 'Alice', 'bob');
      await repository.addFriendRequest('carol', 'Carol', 'bob');
      await repository.declineFriendRequest('alice_bob');
      final requests = await repository.getFriendRequests('bob');
      expect(requests.map((r) => r.senderId), ['carol']);
    });
```

(Standard `setUp` with `FakeFirebaseFirestore` + `FirebaseDatabaseRepository(firebase: firestore)` — mirror `pin_storage_test.dart`.)

- [ ] **Step 2: RED** — `cd packages/firebase_database_repository && flutter test test/src/friend_request_lifecycle_test.dart 2>&1 | tail -5`

- [ ] **Step 3: Implement.** In `addFriendRequest` (currently lines ~385-441):
  - Keep the self/already-friends guards.
  - Replace the two pending QUERIES with deterministic-doc reads:

```dart
    final ownDocRef = _friendCollection.doc(friendRequestDocId(senderId, receiverId));
    final ownDoc = await ownDocRef.get();
    if (ownDoc.exists) {
      final status = (ownDoc.data()! as Map<String, dynamic>)['status'];
      // A declined request stays declined; the sender sees "sent" and the
      // receiver never sees it again (silent re-send suppression).
      if (status == 'declined') return FriendRequestResult.sent;
      return FriendRequestResult.alreadyPending;
    }

    final reverseDoc = await _friendCollection
        .doc(friendRequestDocId(receiverId, senderId))
        .get();
    if (reverseDoc.exists &&
        (reverseDoc.data()! as Map<String, dynamic>)['status'] == 'pending') {
      final reverseModel = FriendRequestModel.fromJson(
        reverseDoc.data()! as Map<String, dynamic>,
      );
      await acceptFriendRequest(reverseModel, senderId);
      return FriendRequestResult.autoAccepted;
    }
```

  - Create at the deterministic id, and map a rules denial (blocked) to silent `sent`:

```dart
    try {
      final documentId = friendRequestDocId(senderId, receiverId);
      await _friendCollection.doc(documentId).set({
        'id': documentId,
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return FriendRequestResult.sent;
    } on FirebaseException catch (e) {
      // A blocked sender is denied by rules; concealment is deliberate —
      // they see the same "sent" as everyone else (spec accepted tradeoff).
      if (e.code == 'permission-denied') return FriendRequestResult.sent;
      rethrow;
    }
```

  - `declineFriendRequest`: replace the delete with `await _friendCollection.doc(requestId).update({'status': 'declined'});`
  - Add the static helper with a doc comment.

Legacy-pending note (verbatim comment above `addFriendRequest`): reverse-direction LEGACY (random-id) pendings won't be found by the deterministic reverse read, so no auto-accept for them — the sender simply creates a new deterministic request and the receiver now has two pendings, one legacy (declinable) and one acceptable. Acceptable drain path.

- [ ] **Step 4: GREEN** — full package suite + package analyze (no new).
- [ ] **Step 5: Commit** — `feat: deterministic friend-request ids with declined retention and silent re-send suppression`

---

### Task 3: Rules lifecycle matrix — friendRequests, friendList, blocks

**Files:**
- Modify: `firestore.rules`
- Modify: `functions/test/rules/firestore-rules.test.ts`

**Interfaces:**
- Consumes: Task 2's deterministic IDs and field shapes; Plan A's `isOwner`.
- Produces: the spec's rules table rows for `friendRequests`, `friends/friendList`, `users/{uid}/blocks`.

- [ ] **Step 1: Failing tests.** Replace/extend the friends + friendRequests groups:

```typescript
describe('blocks', () => {
  test('owner reads and writes own block docs; others cannot', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users/alice/blocks/bob'), { blockedAt: 1 }),
    );
    await assertSucceeds(getDoc(doc(alice(), 'users/alice/blocks/bob')));
    await assertFails(getDoc(doc(bob(), 'users/alice/blocks/bob')));
    await assertFails(
      setDoc(doc(bob(), 'users/alice/blocks/carol'), { blockedAt: 1 }),
    );
  });
});

describe('friendRequests lifecycle', () => {
  const pending = {
    id: 'alice_bob',
    senderId: 'alice',
    receiverId: 'bob',
    senderName: 'Alice',
    status: 'pending',
  };

  test('sender creates at the deterministic id', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'friendRequests/alice_bob'), pending));
  });

  test('create with a mismatched doc id is denied', async () => {
    await assertFails(setDoc(doc(alice(), 'friendRequests/wrong_id'), pending));
  });

  test('create claiming another sender is denied', async () => {
    await assertFails(
      setDoc(doc(bob(), 'friendRequests/alice_bob'), pending),
    );
  });

  test('create is denied when the receiver blocks the sender', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/bob/blocks/alice'), { blockedAt: 1 });
    });
    await assertFails(setDoc(doc(alice(), 'friendRequests/alice_bob'), pending));
  });

  test('create is denied when the sender blocks the receiver', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/alice/blocks/bob'), { blockedAt: 1 });
    });
    await assertFails(setDoc(doc(alice(), 'friendRequests/alice_bob'), pending));
  });

  test('receiver declines pending -> declined; sender cannot', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friendRequests/alice_bob'), pending);
    });
    await assertFails(
      updateDoc(doc(alice(), 'friendRequests/alice_bob'), { status: 'declined' }),
    );
    await assertSucceeds(
      updateDoc(doc(bob(), 'friendRequests/alice_bob'), { status: 'declined' }),
    );
  });

  test('declined docs are immutable to further updates', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friendRequests/alice_bob'), {
        ...pending,
        status: 'declined',
      });
    });
    await assertFails(
      updateDoc(doc(bob(), 'friendRequests/alice_bob'), { status: 'pending' }),
    );
    await assertFails(
      updateDoc(doc(alice(), 'friendRequests/alice_bob'), { status: 'pending' }),
    );
  });

  test('sender may cancel (delete) a pending; receiver may delete (accept path)', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friendRequests/alice_bob'), pending);
    });
    await assertSucceeds(deleteDoc(doc(bob(), 'friendRequests/alice_bob')));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friendRequests/alice_bob'), pending);
    });
    await assertSucceeds(deleteDoc(doc(alice(), 'friendRequests/alice_bob')));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friendRequests/alice_bob'), pending);
    });
    await assertFails(
      deleteDoc(doc(env.authenticatedContext('carol').firestore(), 'friendRequests/alice_bob')),
    );
  });
});

describe('friendList lifecycle', () => {
  test('accepting receiver writes both edges while the pending doc exists', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friendRequests/alice_bob'), {
        senderId: 'alice',
        receiverId: 'bob',
        status: 'pending',
      });
    });
    // bob (receiver) writes alice onto his own list…
    await assertSucceeds(
      setDoc(doc(bob(), 'friends/bob/friendList/alice'), { userId: 'alice' }),
    );
    // …and himself onto alice's list.
    await assertSucceeds(
      setDoc(doc(bob(), 'friends/alice/friendList/bob'), { userId: 'bob' }),
    );
  });

  test('edge writes without a matching pending request are denied', async () => {
    await assertFails(
      setDoc(doc(bob(), 'friends/bob/friendList/carol'), { userId: 'carol' }),
    );
    await assertFails(
      setDoc(doc(bob(), 'friends/carol/friendList/bob'), { userId: 'bob' }),
    );
  });

  test('owner may always delete own edges; you may always delete yourself from another list', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friends/alice/friendList/bob'), { userId: 'bob' });
      await setDoc(doc(ctx.firestore(), 'friends/bob/friendList/alice'), { userId: 'alice' });
    });
    await assertSucceeds(deleteDoc(doc(alice(), 'friends/alice/friendList/bob')));
    await assertSucceeds(deleteDoc(doc(alice(), 'friends/bob/friendList/alice')));
  });

  test('a third party cannot delete someone else's edge', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friends/alice/friendList/bob'), { userId: 'bob' });
    });
    await assertFails(
      deleteDoc(doc(env.authenticatedContext('carol').firestore(), 'friends/alice/friendList/bob')),
    );
  });
});
```

(Keep the existing owner-read/non-participant-read friendList tests; DELETE the old `TRANSITIONAL: signed-in users may write friend edges` test.)

- [ ] **Step 2: RED** via emulators:exec.

- [ ] **Step 3: Implement rules.** Replace the `friends` and `friendRequests` blocks and add `blocks` under `users/{uid}`:

```
      match /blocks/{blockedUid} {
        allow read, write: if isOwner(uid);
      }
```

```
    match /friends/{uid}/friendList/{friendId} {
      allow read: if isOwner(uid);
      // Deleting: you may prune your own list, and you may always remove
      // YOURSELF from someone else's list (unfriend/block cleanup).
      allow delete: if isOwner(uid) ||
        (signedIn() && request.auth.uid == friendId);
      // Creating: only as part of accepting a pending request between the
      // two users involved. The receiver runs the accept batch: they write
      // the sender onto their own list, and themselves onto the sender's.
      allow create, update: if
        (isOwner(uid) &&
          exists(/databases/$(database)/documents/friendRequests/$(friendId + '_' + uid))) ||
        (signedIn() && request.auth.uid == friendId &&
          exists(/databases/$(database)/documents/friendRequests/$(uid + '_' + request.auth.uid)));
    }

    match /friendRequests/{requestId} {
      allow read: if signedIn() &&
        (resource.data.senderId == request.auth.uid ||
         resource.data.receiverId == request.auth.uid);
      allow create: if signedIn() &&
        request.resource.data.senderId == request.auth.uid &&
        requestId == request.resource.data.senderId + '_' + request.resource.data.receiverId &&
        request.resource.data.status == 'pending' &&
        !exists(/databases/$(database)/documents/users/$(request.resource.data.receiverId)/blocks/$(request.auth.uid)) &&
        !exists(/databases/$(database)/documents/users/$(request.auth.uid)/blocks/$(request.resource.data.receiverId));
      // Decline: receiver flips pending -> declined, nothing else, once.
      allow update: if signedIn() &&
        resource.data.receiverId == request.auth.uid &&
        resource.data.status == 'pending' &&
        request.resource.data.status == 'declined' &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status']);
      // Delete: sender cancels, or receiver deletes on accept.
      allow delete: if signedIn() &&
        (resource.data.senderId == request.auth.uid ||
         resource.data.receiverId == request.auth.uid);
    }
```

Note on the accept batch: rules `exists()` evaluates against PRE-batch state, so the edge writes and the request delete in one batch all see the pending doc. Auto-accept (sender accepting the reverse request) is the same shape with roles swapped — covered by the two disjuncts.

- [ ] **Step 4: GREEN** — full emulator suite.
- [ ] **Step 5: Commit** — `feat: rules lifecycle matrix for friend requests, friendship edges, and blocks`

---

### Task 4: `searchByFriendCode` callable (block-aware)

**Files:**
- Create: `functions/src/search-by-friend-code.ts`
- Modify: `functions/src/index.ts`
- Create: `functions/test/rules/search-by-friend-code.integration.test.ts`

**Interfaces:**
- Consumes: users' `friendCode` field, `users/{uid}/blocks`, `friends` edges, `friendRequests` deterministic docs.
- Produces the callable Task 5 consumes: name `searchByFriendCode`; request `{code: string}`; response `{found: false}` or `{found: true, user: {id, username, imageUrl, friendCode}, relationship: 'self'|'friends'|'pendingSent'|'pendingReceived'|'none'}`. Errors: `unauthenticated`; `permission-denied` (anonymous); `invalid-argument` (missing/empty code).

- [ ] **Step 1: Failing integration tests** (same harness conventions as the other two integration files — env vars, functionsTest, `require` after init, recursiveDelete `beforeEach`, `--runInBand` already set):

```typescript
const caller = { uid: 'caller', token: { firebase: { sign_in_provider: 'password' } } };

async function seedTarget() {
  await db.doc('users/target').set({
    id: 'target',
    username: 'Target',
    imageUrl: 'http://x/y.png',
    friendCode: 'YETI-A3F9',
  });
}

test('finds a user by normalized code with relationship none', async () => {
  await seedTarget();
  const r = await wrapped({ data: { code: ' yeti-a3f9 ' }, auth: caller });
  expect(r).toEqual({
    found: true,
    user: { id: 'target', username: 'Target', imageUrl: 'http://x/y.png', friendCode: 'YETI-A3F9' },
    relationship: 'none',
  });
});

test('reports friends / pendingSent / pendingReceived / self', async () => {
  await seedTarget();
  await db.doc('friends/target/friendList/caller').set({ userId: 'caller' });
  expect((await wrapped({ data: { code: 'YETI-A3F9' }, auth: caller })).relationship).toBe('friends');
  await db.recursiveDelete(db.collection('friends'));
  await db.doc('friendRequests/caller_target').set({ senderId: 'caller', receiverId: 'target', status: 'pending' });
  expect((await wrapped({ data: { code: 'YETI-A3F9' }, auth: caller })).relationship).toBe('pendingSent');
  await db.recursiveDelete(db.collection('friendRequests'));
  await db.doc('friendRequests/target_caller').set({ senderId: 'target', receiverId: 'caller', status: 'pending' });
  expect((await wrapped({ data: { code: 'YETI-A3F9' }, auth: caller })).relationship).toBe('pendingReceived');
  await db.doc('users/caller').set({ id: 'caller', friendCode: 'YETI-CCCC' });
  expect((await wrapped({ data: { code: 'YETI-CCCC' }, auth: caller })).relationship).toBe('self');
});

test('declined pending reads as none (sender can silently re-send)', async () => {
  await seedTarget();
  await db.doc('friendRequests/caller_target').set({ senderId: 'caller', receiverId: 'target', status: 'declined' });
  expect((await wrapped({ data: { code: 'YETI-A3F9' }, auth: caller })).relationship).toBe('none');
});

test('not found when target blocks caller, when caller blocks target, or no match', async () => {
  await seedTarget();
  await db.doc('users/target/blocks/caller').set({ blockedAt: 1 });
  expect(await wrapped({ data: { code: 'YETI-A3F9' }, auth: caller })).toEqual({ found: false });
  await db.recursiveDelete(db.doc('users/target').collection('blocks'));
  await db.doc('users/caller/blocks/target').set({ blockedAt: 1 });
  expect(await wrapped({ data: { code: 'YETI-A3F9' }, auth: caller })).toEqual({ found: false });
  expect(await wrapped({ data: { code: 'YETI-ZZZZ' }, auth: caller })).toEqual({ found: false });
});

test('anonymous and unauthenticated callers rejected; empty code invalid', async () => {
  await expect(wrapped({ data: { code: 'YETI-A3F9' } })).rejects.toMatchObject({ code: 'unauthenticated' });
  await expect(
    wrapped({ data: { code: 'YETI-A3F9' }, auth: { uid: 'x', token: { firebase: { sign_in_provider: 'anonymous' } } } }),
  ).rejects.toMatchObject({ code: 'permission-denied' });
  await expect(wrapped({ data: { code: '' }, auth: caller })).rejects.toMatchObject({ code: 'invalid-argument' });
});
```

- [ ] **Step 2: RED** via emulators:exec.

- [ ] **Step 3: Implement** `functions/src/search-by-friend-code.ts`:

```typescript
import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface SearchRequest {
  code?: string;
}

export const searchByFriendCode = onCall<SearchRequest>(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  if (auth.token?.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Anonymous users cannot search.');
  }
  const raw = request.data?.code;
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'code is required.');
  }
  const code = raw.trim().toUpperCase();

  const db = admin.firestore();
  const snapshot = await db
    .collection('users')
    .where('friendCode', '==', code)
    .limit(1)
    .get();
  if (snapshot.empty) return { found: false };

  const target = snapshot.docs[0];
  const targetId = target.id;
  const callerUid = auth.uid;

  // Block hiding: either direction reads as not-found.
  const [targetBlocksCaller, callerBlocksTarget] = await Promise.all([
    db.doc(`users/${targetId}/blocks/${callerUid}`).get(),
    db.doc(`users/${callerUid}/blocks/${targetId}`).get(),
  ]);
  if (targetBlocksCaller.exists || callerBlocksTarget.exists) {
    return { found: false };
  }

  let relationship = 'none';
  if (targetId === callerUid) {
    relationship = 'self';
  } else {
    const [edge, sent, received] = await Promise.all([
      db.doc(`friends/${callerUid}/friendList/${targetId}`).get(),
      db.doc(`friendRequests/${callerUid}_${targetId}`).get(),
      db.doc(`friendRequests/${targetId}_${callerUid}`).get(),
    ]);
    if (edge.exists) relationship = 'friends';
    else if (sent.exists && sent.data()?.status === 'pending') relationship = 'pendingSent';
    else if (received.exists && received.data()?.status === 'pending') relationship = 'pendingReceived';
  }

  const data = target.data();
  return {
    found: true,
    user: {
      id: targetId,
      username: (data.username as string | undefined) ?? '',
      imageUrl: (data.imageUrl as string | undefined) ?? '',
      friendCode: (data.friendCode as string | undefined) ?? code,
    },
    relationship,
  };
});
```

Export from index.ts. Note: legacy random-ID pendings won't be seen by the deterministic reads → relationship 'none'; consistent with the accepted drain story.

- [ ] **Step 4: GREEN** — full emulator suite + pure suite.
- [ ] **Step 5: Commit** — `feat: block-aware searchByFriendCode callable with relationship status`

---

### Task 5: Client — blocking ops + search switches to the callable

**Files:**
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` (add `blockUser`, `unblockUser`, `getBlockedUsers`; replace `searchByFriendCode` with the callable + result type; retire `searchUsers` and client-side `checkRelationshipStatus` IF unused after the SearchBloc switch — grep first, keep if referenced elsewhere)
- Create: `packages/firebase_database_repository/lib/models/friend_search_result.dart` (+ export in models.dart)
- Create: `packages/firebase_database_repository/lib/models/blocked_user_model.dart` (+ export)
- Modify: `lib/friends_list/search_user/bloc/search_bloc.dart` (+ its state file if search state shape changes)
- Test: `packages/firebase_database_repository/test/src/blocking_test.dart`, `packages/firebase_database_repository/test/src/search_by_friend_code_test.dart`, extend the SearchBloc test if one exists (check `ls test/friends_list`)

**Interfaces:**
- Consumes: Task 4's callable contract; Task 3's rules (blocks owner-managed; request deletes participant-scoped).
- Produces (Task 6 relies on):
  - `class BlockedUserModel` — `{userId, username, imageUrl, blockedAt (DateTime?)}` with fromJson/toJson (json_serializable, follow FriendModel's style; run build_runner).
  - `class FriendSearchResult` — `{found: bool, user: UserProfileModel?, relationship: RelationshipStatus?}` (plain Equatable, no codegen; map the callable's relationship string to the existing `RelationshipStatus` enum).
  - `Future<FriendSearchResult> searchByFriendCode(String code)` — callable-backed; callable errors map: `invalid-argument`→ rethrow as ArgumentError, everything else → `FriendSearchResult(found: false)` with a `// conceal` comment? NO — offline must be distinguishable: wrap other FirebaseFunctionsException in a thrown `Exception('search unavailable')` so the bloc can show its existing error state. found:false is ONLY for a true not-found.
  - `Future<void> blockUser({required String currentUserId, required BlockedUserModel target})` — batch: set `users/{me}/blocks/{target.userId}` (blockedAt serverTimestamp + denormalized username/imageUrl), delete both friendship edges, delete `friendRequests/{me}_{target}` and `{target}_{me}` docs ONLY after reading them and confirming they exist — under the Task 3 rules, a delete of a NONEXISTENT doc evaluates `resource.data` against null and is DENIED, which would fail the entire block batch. Read both deterministic docs first; add only the existing ones to the batch. Plus query BOTH legacy pending directions (senderId/receiverId equality, status pending) and delete those (query results always exist) in the same batch.
  - `Future<void> unblockUser({required String currentUserId, required String targetUserId})` — delete the block doc.
  - `Stream<List<BlockedUserModel>> getBlockedUsers(String userId)` — snapshots of `users/{uid}/blocks` ordered by blockedAt desc.
- SearchBloc: `SearchByFriendCode` handler calls the new repository method; `SearchLoaded` carries the found user + relationship (adapt its current state shape minimally — read the bloc first); `AddFriendRequest` handler unchanged.

- [ ] **Step 1: Failing tests.** `blocking_test.dart` (fake_cloud_firestore): block removes both edges + both deterministic request docs + a seeded legacy pending (random id, senderId target→me), writes the block doc with denormalized fields; unblock removes only the block doc (edges stay gone, no re-friend); `getBlockedUsers` streams seeded docs newest-first. `search_by_friend_code_test.dart` (mocktail callable, mirror `validate_pin_test.dart`): found:true payload maps to FriendSearchResult with RelationshipStatus.pendingSent; found:false maps; `unavailable` throws.

- [ ] **Step 2: RED** (targeted files).
- [ ] **Step 3: Implement** per the interfaces above. SearchBloc: read `lib/friends_list/search_user/bloc/*` first; keep event names; internal call swap + state payload change only as far as the page requires (Task 6 adjusts the page).
- [ ] **Step 4: GREEN** — package suite, root `flutter test test/friends_list` (if exists) + full root suite, analyze baseline.
- [ ] **Step 5: Commit** — `feat: client blocking operations and callable-backed friend-code search`

---

### Task 6: Blocking UI — block/unblock actions + blocked-users screen + legacy-accept copy

**Files:**
- Modify: `lib/friends_list/friends_list/friends_list.dart` (block action on FriendCard via long-press menu or trailing overflow menu — match the existing delete-confirmation pattern)
- Modify: `lib/friends_list/search_user/search_user_page.dart` (search result renders from `FriendSearchResult`; add Block option when relationship == friends? NO — search-result block is out of scope creep; skip)
- Create: `lib/friends_list/blocked_users/view/blocked_users_page.dart` + `lib/friends_list/blocked_users/bloc/blocked_users_bloc.dart` (+ barrel if the feature folders use them)
- Modify: `lib/friends_list/friends_list_page.dart` (entry point: app-bar action or menu → blocked users page), `lib/app/app_router/app_router.dart` (route)
- Modify: `lib/friends_list/requests/bloc/friend_request_bloc.dart` (accept error → distinguish permission-denied as legacy-request case)
- Modify: `lib/friends_list/requests/friend_request_page.dart` (snackbar copy for legacy-accept failure)
- Modify: `lib/l10n/arb/app_en.arb` + `app_es.arb`
- Test: bloc test for BlockedUsersBloc; widget test for blocked list + unblock; bloc test for block-from-friends-list dispatch; FriendRequestBloc legacy-accept mapping test

**Interfaces:**
- Consumes: Task 5's repository ops.
- Produces: user-visible blocking complete.

- [ ] **Step 1: l10n keys** (en + es): `blockUserAction` ("Block"), `blockUserConfirmTitle` ("Block {name}?"), `blockUserConfirmBody` ("They'll be removed from your friends and won't be able to find you or send requests. They won't be notified."), `unblockUserAction` ("Unblock"), `blockedUsersTitle` ("Blocked Users"), `blockedUsersEmpty` ("You haven't blocked anyone."), `legacyRequestAcceptError` ("This request was sent from an older version. Ask them to re-send it."). Spanish equivalents. gen-l10n.
- [ ] **Step 2: BlockedUsersBloc (TDD):** events `LoadBlockedUsers(userId)` (subscribes to the stream), `UnblockUser(userId, targetUserId)`; states loading/loaded(list)/error. RED → implement → GREEN.
- [ ] **Step 3: FriendRequestBloc accept mapping (TDD):** stub `acceptFriendRequest` throwing a `FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied')`-wrapped error (match how the repository surfaces it — read the repo's catch: it wraps in `Exception('Failed to accept friend request: ...')`; ADJUST the repository's `acceptFriendRequest` catch to rethrow FirebaseException permission-denied as a typed `LegacyFriendRequestException` defined next to the other repo exceptions, and map THAT in the bloc to a new state flag). RED → implement → GREEN.
- [ ] **Step 4: UI wiring:** friends-list block action with confirmation dialog (dispatches via a small event on the existing FriendBloc or directly repository via a new event `BlockFriend` on FriendBloc — extend FriendBloc: event + reload after); blocked-users page (ListView of BlockedUserModel with unblock button + confirmation); route + entry point (menu icon on FriendsListPage app bar); legacy-accept snackbar on the requests page. Widget tests: blocked page renders seeded models and unblock dispatches; friends list shows block action.
- [ ] **Step 5: GREEN** — `flutter test test/friends_list` + full root + analyze baseline.
- [ ] **Step 6: Commit** — `feat: blocking UI — block from friends list, blocked-users management, legacy-request copy`

---

### Task 7: Verification + INDEX

- [ ] **Step 1:** Full battery: root analyze (165 baseline) + root test + package test + functions build/test + emulators:exec rules suite. All green.
- [ ] **Step 2:** INDEX: Plan C row → complete; move "Plan C must own" items to "Resolved in Plan C"; add a **data-migration note**: legacy random-ID pending requests can be declined but not accepted after deploy (accept shows the re-send copy); optionally clean them with a one-time console query (`friendRequests` where `status == 'pending'` created before the deploy date) — Josh's call.
- [ ] **Step 3:** Commit — `chore: verify friends plan C; update index`
