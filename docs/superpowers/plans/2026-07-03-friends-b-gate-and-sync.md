# Friends Plan B: Legacy Gate & Game Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce name+PIN completeness for all users via the existing onboarding gate, and move game fan-out server-side (trigger) so cross-user `matches` writes can be denied by rules — plus the game-over `firebaseId` overwrite guard and the Plan-A carry-overs (PinNotSet, hasPin self-healing, rules header).

**Architecture:** Spec phases 2–3 of `docs/superpowers/specs/2026-07-03-friends-feature-design.md`, plus the "Plan B must own" list in `docs/superpowers/plans/2026-07-03-friends-INDEX.md`. An `onGameCreated` Firestore trigger fans a saved game out to `hostId ∪ players[].firebaseId`; the client fan-out (`syncGameToPlayers`) is deleted and the TRANSITIONAL cross-user `matches` write rule flips to owner-only (game-code import still writes the user's OWN subcollection, so it keeps working). AppBloc gates on `UserProfileModel.isComplete` instead of bare `onboardingComplete`, backed by a `hasPin` self-heal in `migrateLegacyPin`.

**Tech Stack:** unchanged from Plan A (firebase-functions v2 `onDocumentCreated`, `@firebase/rules-unit-testing`, Flutter BLoC, fake_cloud_firestore, mocktail/bloc_test).

## Global Constraints

- **Environment:** the global `firebase` binary is broken for `emulators:exec` — always use `npx firebase-tools@14.9.0 emulators:exec --only firestore "npm --prefix functions run test:rules"` from the repo root.
- **Analyzer baseline:** root `flutter analyze` has ~165 pre-existing issues (app_ui/gallery). Gate = no NEW issues.
- Fan-out recipient set is exactly `set(hostId ∪ players[].firebaseId)` — host always gets a copy even when not a player (existing behavior preserved); string-only players (null firebaseId) are skipped; duplicates deduped.
- The trigger copies the game document verbatim to `users/{id}/matches/{gameId}` where `gameId` is the `games/` doc id (idempotent; matches the old client fan-out's doc-id convention and the game-code import path).
- `users/{uid}/matches/{gameId}` rules become owner-only read AND write. The game-code import flow (user copies a game into their OWN matches) must keep passing rules tests.
- Gate semantics: `onboardingRequired` when `profile == null || !profile.isComplete`; anonymous/unauthenticated paths and the network-failure fallback to `authenticated` are UNCHANGED.
- `PinValidationResult` gains exactly one subtype: `PinNotSet` (const, no fields); `failed-precondition` maps to it; every other non-lockout error still maps to `PinCheckUnavailable`.
- Account-owner dropdown: slots with `firebaseId` set to someone OTHER than the current user are excluded; a "I'm not playing" sentinel option (`GameOverBloc.notPlayingId`) must exist so the page never dead-ends when all slots are friend-linked; the bloc must also guard (never clobber a foreign `firebaseId`) even if the UI misbehaves.
- All new user-facing strings in BOTH `lib/l10n/arb/app_en.arb` and `app_es.arb`; run `flutter gen-l10n --arb-dir="lib/l10n/arb"`.
- Commit after every task; TDD with RED evidence captured before implementation.
- Do not deploy; Task 8 updates the INDEX deploy gate instead.

---

### Task 1: `PinNotSet` end-to-end (model → repository → bloc → dialog → l10n)

**Files:**
- Modify: `packages/firebase_database_repository/lib/models/pin_validation_result.dart`
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` (validatePin error mapping)
- Modify: `packages/firebase_database_repository/test/models/pin_validation_result_test.dart`
- Modify: `packages/firebase_database_repository/test/src/validate_pin_test.dart`
- Modify: `lib/player/view/bloc/player_customization_state.dart` (PinFlowError enum)
- Modify: `lib/player/view/bloc/player_customization_bloc.dart` (`_onValidatePin` switch)
- Modify: `lib/player/view/customize_player_page.dart` (`_pinErrorText`)
- Modify: `lib/l10n/arb/app_en.arb`, `lib/l10n/arb/app_es.arb`
- Test: `test/player/player_customization_bloc_test.dart`

**Interfaces:**
- Consumes: Plan A's sealed `PinValidationResult`, `PinFlowError`, callable error contract (`failed-precondition` = target has no PIN).
- Produces: `final class PinNotSet extends PinValidationResult` (const, no fields); `PinFlowError.notSet`; l10n key `pinNotSetError`.

- [ ] **Step 1: Failing tests.** In `pin_validation_result_test.dart` extend the equality test with `expect(const PinNotSet(), const PinNotSet());` and add `PinNotSet() => 'notSet',` to the exhaustive-switch helper (the sealed switch will not compile until the subtype exists — that IS the red state; note the compile error as RED evidence). In `validate_pin_test.dart` replace the existing `failed-precondition surfaces as unavailable` test with:

```dart
  test('failed-precondition maps to PinNotSet', () async {
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(code: 'failed-precondition', message: 'no pin'),
    );
    expect(
      await repository.validatePin(targetUserId: 'f', pin: '0742'),
      const PinNotSet(),
    );
  });
```

In `test/player/player_customization_bloc_test.dart` add to the `ValidatePin` group:

```dart
      blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
        'emits notSet on PinNotSet',
        build: () {
          when(
            () => firebaseDatabaseRepository.validatePin(
              targetUserId: 'friend1',
              pin: '0742',
            ),
          ).thenAnswer((_) async => const PinNotSet());
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const ValidatePin(pin: '0742', friendUserId: 'friend1')),
        expect: () => [
          isA<PlayerCustomizationState>().having(
            (s) => s.pinFlowError,
            'pinFlowError',
            PinFlowError.notSet,
          ),
        ],
      );
```

- [ ] **Step 2: RED.** `cd packages/firebase_database_repository && flutter test` → compile errors (`PinNotSet` undefined). Then root: `flutter test test/player` → same.

- [ ] **Step 3: Implement.**

`pin_validation_result.dart` — add after `PinLockedOut`:

```dart
/// The target user has not set a PIN yet, so validation cannot run.
final class PinNotSet extends PinValidationResult {
  /// Creates a not-set result.
  const PinNotSet();
}
```

Repository `validatePin` — inside the `FirebaseFunctionsException` catch, before the generic fallback:

```dart
      if (e.code == 'failed-precondition') {
        return const PinNotSet();
      }
```

`player_customization_state.dart` — add enum value with doc comment:

```dart
  /// The selected friend has not set a PIN yet.
  notSet,
```

`player_customization_bloc.dart` `_onValidatePin` — add the case (sealed switch forces it):

```dart
      case PinNotSet():
        emit(
          state.copyWith(
            pinValidated: false,
            pinFlowError: PinFlowError.notSet,
            pinLockedUntil: () => null,
          ),
        );
```

`customize_player_page.dart` `_pinErrorText` — add:

```dart
      PinFlowError.notSet => l10n.pinNotSetError,
```

l10n — `app_en.arb`: `"pinNotSetError": "This friend hasn't set a PIN yet. Ask them to set one in their profile.",` and `app_es.arb`: `"pinNotSetError": "Este amigo aún no ha configurado un PIN. Pídele que configure uno en su perfil.",` then `flutter gen-l10n --arb-dir="lib/l10n/arb"`.

- [ ] **Step 4: GREEN.** `cd packages/firebase_database_repository && flutter test` and root `flutter test test/player && flutter analyze` (no new issues).

- [ ] **Step 5: Commit.**

```bash
git add packages/firebase_database_repository lib/player lib/l10n test/player
git commit -m "feat: PinNotSet result surfaces friends without a PIN distinctly from offline"
```

---

### Task 2: `migrateLegacyPin` self-heals the `hasPin` flag

**Files:**
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` (`migrateLegacyPin`)
- Modify: `packages/firebase_database_repository/test/src/pin_storage_test.dart`

**Interfaces:**
- Consumes: Plan A's `migrateLegacyPin`, `_credentialsDoc`.
- Produces: guarantee for Task 3 — after `migrateLegacyPin`, a user whose credentials doc exists has `hasPin: true` on the profile even if an old-version client's full-doc write wiped the flag.

- [ ] **Step 1: Failing tests** in `pin_storage_test.dart`, inside the `migrateLegacyPin` group:

```dart
    test('repairs a wiped hasPin flag when credentials exist', () async {
      await firestore.doc('users/u1/private/credentials').set({
        'pinHash': 'saltedHash',
        'salt': 'realsalt',
      });
      // Old-version client full-doc write wiped the flag and has no pin field.
      await firestore.collection('users').doc('u1').set({'username': 'j'});

      await repository.migrateLegacyPin('u1');
      await Future<void>.delayed(Duration.zero);

      final profile = await firestore.doc('users/u1').get();
      expect(profile.data()!['hasPin'], isTrue);
    });

    test('does not create credentials or set hasPin for a user with none',
        () async {
      await firestore.collection('users').doc('u1').set({'username': 'j'});
      await repository.migrateLegacyPin('u1');
      await Future<void>.delayed(Duration.zero);
      final profile = await firestore.doc('users/u1').get();
      expect(profile.data()!.containsKey('hasPin'), isFalse);
    });
```

- [ ] **Step 2: RED.** `cd packages/firebase_database_repository && flutter test test/src/pin_storage_test.dart` — first new test fails (flag not repaired).

- [ ] **Step 3: Implement.** In `migrateLegacyPin`, replace the early return for a missing legacy hash:

```dart
      final legacyHash = profile.data()?['pin'] as String?;
      if (legacyHash == null || legacyHash.isEmpty) {
        // Self-heal: an old-version client's full-doc profile write can
        // wipe the hasPin flag after migration already ran. If the
        // credentials doc exists but the flag is missing, repair it so
        // the completeness gate does not bounce a PIN-holding user back
        // into onboarding.
        if (profile.data()?['hasPin'] != true) {
          final credentials = await _credentialsDoc(userId).get();
          if (credentials.exists) {
            unawaited(
              profileRef
                  .set({'hasPin': true}, SetOptions(merge: true))
                  .catchError((Object _) {}),
            );
          }
        }
        return;
      }
```

(The write is fire-and-forget for the same offline-hang reason as the batch commit; the gate's `isComplete` still passes this login via the legacy-pin OR-branch only when a legacy pin exists — for the wiped-flag cohort the repair lands from local cache before the next profile read in practice, and worst-case the user sees onboarding pre-filled once.)

- [ ] **Step 4: GREEN.** `cd packages/firebase_database_repository && flutter test` (all, incl. Plan A migration tests).

- [ ] **Step 5: Commit.**

```bash
git add packages/firebase_database_repository
git commit -m "fix: migrateLegacyPin repairs a wiped hasPin flag from old-client profile writes"
```

---

### Task 3: AppBloc gates on `isComplete`

**Files:**
- Modify: `lib/app/bloc/app_bloc.dart` (`_onUserChanged`, the profile evaluation)
- Modify: `test/app/bloc/app_bloc_test.dart`

**Interfaces:**
- Consumes: `UserProfileModel.isComplete` (Plan A Task 5), Task 2's self-heal ordering guarantee (migration runs before the fetch — already wired in Plan A Task 10).
- Produces: the spec's legacy-enforcement behavior — users missing username OR PIN are routed to (pre-filled) onboarding.

- [ ] **Step 1: Failing tests.** In `test/app/bloc/app_bloc_test.dart`, add a gate matrix group (reuse the file's existing fixtures/mocks; each case stubs `migrateLegacyPin` lenient + `getUserProfileOnce` with the profile shown and asserts the emitted state):

```dart
      group('completeness gate', () {
        AppState expectFor(UserProfileModel? profile) {
          when(() => firebaseDatabaseRepository.getUserProfileOnce(any()))
              .thenAnswer((_) async => profile);
          return const AppState.authenticated(User(id: 'user1'));
        }

        blocTest<AppBloc, AppState>(
          'complete profile → authenticated',
          setUp: () => expectFor(
            const UserProfileModel(
              id: 'user1',
              username: 'josh',
              hasPin: true,
              onboardingComplete: true,
            ),
          ),
          build: buildBloc,
          act: (bloc) => bloc.add(AppUserChanged(authenticatedUser)),
          expect: () => [isA<AppState>().having((s) => s.status, 'status', AppStatus.authenticated)],
        );

        blocTest<AppBloc, AppState>(
          'onboarded but missing PIN → onboardingRequired',
          setUp: () => expectFor(
            const UserProfileModel(
              id: 'user1',
              username: 'josh',
              onboardingComplete: true,
            ),
          ),
          build: buildBloc,
          act: (bloc) => bloc.add(AppUserChanged(authenticatedUser)),
          expect: () => [isA<AppState>().having((s) => s.status, 'status', AppStatus.onboardingRequired)],
        );

        blocTest<AppBloc, AppState>(
          'onboarded but empty username → onboardingRequired',
          setUp: () => expectFor(
            const UserProfileModel(
              id: 'user1',
              username: '',
              hasPin: true,
              onboardingComplete: true,
            ),
          ),
          build: buildBloc,
          act: (bloc) => bloc.add(AppUserChanged(authenticatedUser)),
          expect: () => [isA<AppState>().having((s) => s.status, 'status', AppStatus.onboardingRequired)],
        );

        blocTest<AppBloc, AppState>(
          'legacy unmigrated pin field counts as complete',
          setUp: () => expectFor(
            const UserProfileModel(
              id: 'user1',
              username: 'josh',
              pin: 'legacyhash',
              onboardingComplete: true,
            ),
          ),
          build: buildBloc,
          act: (bloc) => bloc.add(AppUserChanged(authenticatedUser)),
          expect: () => [isA<AppState>().having((s) => s.status, 'status', AppStatus.authenticated)],
        );
      });
```

(Adapt the helper shape to the file's conventions — the meaningful content is the four profile fixtures and expected statuses. Keep the existing tests: null-profile → onboardingRequired and network-failure → authenticated already exist from earlier work; if they don't, add them to this matrix.)

- [ ] **Step 2: RED.** `flutter test test/app` — the missing-PIN and empty-username cases fail (gate currently only checks `onboardingComplete`).

- [ ] **Step 3: Implement.** In `_onUserChanged`, replace the evaluation:

```dart
        if (profile == null || !profile.isComplete) {
          return emit(AppState.onboardingRequired(event.user));
        }
        return emit(AppState.authenticated(event.user));
```

(Only the condition changes — `!profile.onboardingComplete` becomes `!profile.isComplete`. Generation guard, anonymous/unauthenticated paths, and the catch-fallback stay byte-identical.)

- [ ] **Step 4: GREEN.** `flutter test test/app && flutter analyze`.

- [ ] **Step 5: Commit.**

```bash
git add lib/app test/app
git commit -m "feat: onboarding gate requires username and PIN via UserProfileModel.isComplete"
```

---

### Task 4: `onGameCreated` server-side fan-out trigger

**Files:**
- Create: `functions/src/on-game-created.ts`
- Modify: `functions/src/index.ts`
- Create: `functions/test/rules/on-game-created.integration.test.ts`

**Interfaces:**
- Consumes: `games/{docId}` document shape (`hostId: string`, `players: [{firebaseId?: string|null, ...}]`, full `GameModel` JSON with `id` already stamped by `saveGameStats`).
- Produces: server-guaranteed copies at `users/{id}/matches/{gameId}` for `set(hostId ∪ players[].firebaseId)`; Tasks 5–6 rely on this to remove the client fan-out.

- [ ] **Step 1: Failing integration test** — `functions/test/rules/on-game-created.integration.test.ts`:

```typescript
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.GCLOUD_PROJECT = 'magic-yeti-fn-test';

import functionsTest from 'firebase-functions-test';
import * as admin from 'firebase-admin';

const testEnv = functionsTest({ projectId: 'magic-yeti-fn-test' });
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { onGameCreated } = require('../../src/on-game-created');

const db = admin.firestore();
const wrapped = testEnv.wrap(onGameCreated);

afterAll(() => {
  testEnv.cleanup();
});

beforeEach(async () => {
  const collections = await db.listCollections();
  await Promise.all(collections.map((c) => db.recursiveDelete(c)));
});

function gameDoc(overrides: Record<string, unknown> = {}) {
  return {
    id: 'g1',
    hostId: 'host',
    roomId: 'AB2C',
    winnerId: 'p1',
    players: [
      { id: 'p1', name: 'Josh', firebaseId: 'host' },
      { id: 'p2', name: 'Friend', firebaseId: 'friend1' },
      { id: 'p3', name: 'Guest', firebaseId: null },
      { id: 'p4', name: 'Dup', firebaseId: 'friend1' },
    ],
    ...overrides,
  };
}

async function fireWith(data: Record<string, unknown>, gameId = 'g1') {
  const snap = testEnv.firestore.makeDocumentSnapshot(data, `games/${gameId}`);
  await wrapped({ data: snap, params: { gameId } });
}

test('fans out to host and linked players, deduped, skipping null ids', async () => {
  await fireWith(gameDoc());
  const host = await db.doc('users/host/matches/g1').get();
  const friend = await db.doc('users/friend1/matches/g1').get();
  expect(host.exists).toBe(true);
  expect(friend.exists).toBe(true);
  expect(friend.data()!.roomId).toBe('AB2C');
  const all = await db.collectionGroup('matches').get();
  expect(all.size).toBe(2);
});

test('host gets a copy even when not in any player slot', async () => {
  await fireWith(
    gameDoc({
      players: [{ id: 'p1', name: 'Friend', firebaseId: 'friend1' }],
    }),
  );
  expect((await db.doc('users/host/matches/g1').get()).exists).toBe(true);
});

test('no linked players and empty hostId writes nothing', async () => {
  await fireWith(
    gameDoc({ hostId: '', players: [{ id: 'p1', name: 'X', firebaseId: null }] }),
  );
  const all = await db.collectionGroup('matches').get();
  expect(all.size).toBe(0);
});

test('is idempotent: re-firing overwrites the same doc, not a new one', async () => {
  await fireWith(gameDoc());
  await fireWith(gameDoc());
  const friendDocs = await db.collection('users/friend1/matches').get();
  expect(friendDocs.size).toBe(1);
});

test('malformed firebaseId values are skipped without throwing', async () => {
  await fireWith(
    gameDoc({
      players: [
        { id: 'p1', firebaseId: 42 },
        { id: 'p2', firebaseId: 'ok-user' },
      ],
    }),
  );
  expect((await db.doc('users/ok-user/matches/g1').get()).exists).toBe(true);
});
```

- [ ] **Step 2: RED.** `cd functions && npm run build` fails or the suite fails with `Cannot find module '../../src/on-game-created'`:
`npx firebase-tools@14.9.0 emulators:exec --only firestore "npm --prefix functions run test:rules"`

- [ ] **Step 3: Implement `functions/src/on-game-created.ts`:**

```typescript
import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Fans a newly saved game out to every linked player's match history.
 * Recipients: set(hostId ∪ players[].firebaseId). Idempotent — the copy
 * doc id is the games/ doc id, so retries and re-fires overwrite in place.
 */
export const onGameCreated = onDocumentCreated(
  { document: 'games/{gameId}', retry: true },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const game = snapshot.data();
    const gameId = event.params.gameId;

    const ids = new Set<string>();
    if (typeof game.hostId === 'string' && game.hostId.length > 0) {
      ids.add(game.hostId);
    }
    const players = Array.isArray(game.players) ? game.players : [];
    for (const player of players) {
      const firebaseId = player?.firebaseId;
      if (typeof firebaseId === 'string' && firebaseId.length > 0) {
        ids.add(firebaseId);
      }
    }
    if (ids.size === 0) return;

    const db = admin.firestore();
    const batch = db.batch();
    for (const id of ids) {
      batch.set(db.doc(`users/${id}/matches/${gameId}`), game);
    }
    await batch.commit();
  },
);
```

`functions/src/index.ts`:

```typescript
export { validatePin } from './validate-pin';
export { onGameCreated } from './on-game-created';
```

- [ ] **Step 4: GREEN.** Build + run the full rules script (Task 2/4 suites must stay green):
`cd functions && npm run build && cd .. && npx firebase-tools@14.9.0 emulators:exec --only firestore "npm --prefix functions run test:rules"` and `cd functions && npm test` (pure suite untouched).
If `testEnv.wrap` for v2 Firestore triggers requires a different invocation shape (CloudEvent envelope), adapt the TEST harness only — the trigger contract (paths, recipient set, idempotency) is binding; report the adaptation.

- [ ] **Step 5: Commit.**

```bash
git add functions/src/on-game-created.ts functions/src/index.ts functions/test/rules/on-game-created.integration.test.ts
git commit -m "feat: onGameCreated trigger fans games out to host and linked players"
```

---

### Task 5: Tighten `matches` rules to owner-only + rules header

**Files:**
- Modify: `firestore.rules`
- Modify: `functions/test/rules/firestore-rules.test.ts`

**Interfaces:**
- Consumes: Task 4's trigger (Admin SDK bypasses rules, so server fan-out is unaffected).
- Produces: the spec's rules-table row `users/{uid}/matches/** — read owner / write owner`.

- [ ] **Step 1: Failing tests.** In `firestore-rules.test.ts`, replace the TRANSITIONAL matches test:

```typescript
  test('cross-user match writes are denied (fan-out is server-side)', async () => {
    await assertFails(
      setDoc(doc(bob(), 'users/alice/matches/g2'), { id: 'g2' }),
    );
  });

  test('owner may write own matches (game-code import path)', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users/alice/matches/g3'), { id: 'g3' }),
    );
  });
```

- [ ] **Step 2: RED.** `npx firebase-tools@14.9.0 emulators:exec --only firestore "npm --prefix functions run test:rules"` — the denial test fails against current transitional rules.

- [ ] **Step 3: Implement.** In `firestore.rules`: replace the matches block:

```
      match /matches/{gameId} {
        // Owner-only. Fan-out to other players happens server-side via
        // the onGameCreated trigger (Admin SDK bypasses rules); the
        // owner write covers the game-code import flow.
        allow read, write: if isOwner(uid);
      }
```

And add the header at the very top of the file (before `rules_version`... rules files require `rules_version` first — place the comment immediately AFTER the `rules_version = '2';` line):

```
// Magic Yeti Firestore rules — staged hardening.
// Blocks labeled TRANSITIONAL are deliberately permissive so the shipped
// client keeps working, and are tightened by the named follow-up plan.
// Strategy + deploy gate: docs/superpowers/plans/2026-07-03-friends-INDEX.md
```

- [ ] **Step 4: GREEN.** Same emulators:exec command — full rules suite green (including Task 4's trigger tests, which use the Admin SDK and must be unaffected).

- [ ] **Step 5: Commit.**

```bash
git add firestore.rules functions/test/rules/firestore-rules.test.ts
git commit -m "feat: matches writes are owner-only; rules header documents staged hardening"
```

---

### Task 6: GameOverBloc — overwrite guard, not-playing sentinel, preselect, drop client fan-out

**Files:**
- Modify: `lib/life_counter/bloc/game_over_bloc.dart`
- Modify: `lib/life_counter/view/game_over_page.dart:56-64` (bloc construction gains `currentUserId`)
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` (delete `syncGameToPlayers`)
- Test: `test/life_counter/bloc/game_over_bloc_test.dart` (create or extend; check `ls test/life_counter` first)

**Interfaces:**
- Consumes: Task 4 (fan-out now server-side).
- Produces: `GameOverBloc({required List<Player> players, required String currentUserId, required FirebaseDatabaseRepository firebaseDatabaseRepository})`; `static const notPlayingId = 'game_over_not_playing';` initial `selectedPlayerId` preselected to the slot whose `firebaseId == currentUserId` (else null). Task 7's UI depends on these exact names.

- [ ] **Step 1: Failing bloc tests** (mirror repo bloc-test conventions; mock the repository):

```dart
    group('GameOverBloc', () {
      final linkedFriendSlot = basePlayer.copyWith(
        // adapt: construct a Player with id 'p2', firebaseId 'friend1', placement 2
      );

      test('preselects the slot already linked to the current user', () {
        final bloc = buildBloc(
          players: [hostLinkedSlot, unlinkedSlot], // hostLinkedSlot.firebaseId == 'host'
          currentUserId: 'host',
        );
        expect(bloc.state.selectedPlayerId, hostLinkedSlot.id);
      });

      blocTest<GameOverBloc, GameOverState>(
        'never clobbers a slot linked to another account',
        build: () => buildBloc(
          players: [linkedFriendSlot, unlinkedSlot],
          currentUserId: 'host',
        ),
        seed: () => /* state with selectedPlayerId: linkedFriendSlot.id */,
        act: (bloc) => bloc.add(SendGameOverStatsEvent(gameModel: gameModel, userId: 'host')),
        verify: (_) {
          final saved = verify(
            () => firebaseDatabaseRepository.saveGameStats(captureAny()),
          ).captured.single as GameModel;
          final slot = saved.players.firstWhere((p) => p.id == linkedFriendSlot.id);
          expect(slot.firebaseId, 'friend1'); // NOT 'host'
        },
      );

      blocTest<GameOverBloc, GameOverState>(
        'notPlayingId assigns the host uid to no slot',
        build: () => buildBloc(players: [linkedFriendSlot, unlinkedSlot], currentUserId: 'host'),
        seed: () => /* state with selectedPlayerId: GameOverBloc.notPlayingId */,
        act: (bloc) => bloc.add(SendGameOverStatsEvent(gameModel: gameModel, userId: 'host')),
        verify: (_) {
          final saved = verify(
            () => firebaseDatabaseRepository.saveGameStats(captureAny()),
          ).captured.single as GameModel;
          expect(saved.players.every((p) => p.firebaseId != 'host'), isTrue);
        },
      );

      blocTest<GameOverBloc, GameOverState>(
        'does not call client-side fan-out',
        build: () => buildBloc(players: [unlinkedSlot], currentUserId: 'host'),
        seed: () => /* selectedPlayerId: unlinkedSlot.id */,
        act: (bloc) => bloc.add(SendGameOverStatsEvent(gameModel: gameModel, userId: 'host')),
        verify: (_) {
          // syncGameToPlayers no longer exists on the repository; this test
          // asserts the ONLY repository call is saveGameStats.
          verify(() => firebaseDatabaseRepository.saveGameStats(any())).called(1);
          verifyNoMoreInteractions(firebaseDatabaseRepository);
        },
      );
    });
```

(Flesh out `basePlayer`/`gameModel` fixtures from `player_repository`'s `Player` constructor — see `packages/player_repository/lib/models/player.dart`; a minimal Player needs id, name, playerNumber, lifePoints, color, opponents, state and placement for eliminated players. Read the file and build the smallest valid fixtures.)

- [ ] **Step 2: RED.** `flutter test test/life_counter` — constructor lacks `currentUserId`, guard absent, fan-out still called.

- [ ] **Step 3: Implement.** `game_over_bloc.dart`:

Constructor and preselect:

```dart
  GameOverBloc({
    required List<Player> players,
    required String currentUserId,
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
  })  : _firebaseDatabaseRepository = firebaseDatabaseRepository,
        super(
          GameOverState(
            standings: List<Player>.from(players)
              ..sort((a, b) => a.placement.compareTo(b.placement)),
            selectedPlayerId: players
                .where((p) => p.firebaseId == currentUserId)
                .map((p) => p.id)
                .firstOrNull,
            firstPlayerId: null,
          ),
        ) {
```

Sentinel:

```dart
  /// Dropdown sentinel meaning the current user is not one of the players.
  static const notPlayingId = 'game_over_not_playing';
```

Guarded assignment in `_onSendGameStatsToDatabase` (replace the `firebaseId:` lambda):

```dart
          firebaseId: () {
            if (player.id != state.selectedPlayerId) return player.firebaseId;
            // Never clobber a slot already linked to another account
            // (PIN-linked friend); the UI excludes these, this guards it.
            if (player.firebaseId != null &&
                player.firebaseId != event.userId) {
              return player.firebaseId;
            }
            return event.userId;
          },
```

Delete the fan-out block (lines collecting `playerFirebaseIds` and the `syncGameToPlayers` call) — the trigger owns it; keep `saveGameStats` + the success emit. Add a one-line comment: `// Fan-out to players' match histories happens server-side (onGameCreated).`

`game_over_page.dart` bloc construction:

```dart
      create: (context) => GameOverBloc(
        players: context.read<PlayerRepository>().getPlayers(),
        currentUserId: context.read<AppBloc>().state.user.id,
        firebaseDatabaseRepository: context.read<FirebaseDatabaseRepository>(),
      ),
```

Repository: delete `syncGameToPlayers` entirely (its doc comment too). `addMatchToPlayerHistory` STAYS (game-code import uses it). If `firstOrNull` needs it, `package:collection` is already a transitive dep — import `package:collection/collection.dart`; if the analyzer objects to the dependency, use `players.where(...).map((p) => p.id).cast<String?>().firstWhere((_) => true, orElse: () => null)` — prefer `firstOrNull`.

- [ ] **Step 4: GREEN.** `flutter test test/life_counter && cd packages/firebase_database_repository && flutter test && cd ../.. && flutter analyze` (deleting `syncGameToPlayers` must not break anything else — `grep -rn "syncGameToPlayers" lib/ test/ packages/` must return zero hits).

- [ ] **Step 5: Commit.**

```bash
git add lib/life_counter packages/firebase_database_repository test/life_counter
git commit -m "feat: game-over guard for linked slots; fan-out moves fully server-side"
```

---

### Task 7: Game-over page UI — dropdown exclusion, linked badges, not-playing option

**Files:**
- Modify: `lib/life_counter/view/game_over_page.dart` (`_DetailsPanel`, `_PlayerDropdown` usage at lines ~644-649; `_StandingRow`)
- Modify: `lib/l10n/arb/app_en.arb`, `lib/l10n/arb/app_es.arb`
- Test: `test/life_counter/view/game_over_page_test.dart` (create; light widget coverage)

**Interfaces:**
- Consumes: Task 6's `GameOverBloc.notPlayingId`, preselect, and constructor.
- Produces: final phase-2/3 UX.

- [ ] **Step 1: l10n keys.** `app_en.arb`:

```json
  "notPlayingOption": "I'm not playing",
  "linkedAccountBadge": "Linked to a friend's account",
```

`app_es.arb`:

```json
  "notPlayingOption": "No estoy jugando",
  "linkedAccountBadge": "Vinculado a la cuenta de un amigo",
```

Run `flutter gen-l10n --arb-dir="lib/l10n/arb"`.

- [ ] **Step 2: Failing widget test** — `test/life_counter/view/game_over_page_test.dart`: pump `GameOverView` wrapped with mocked `GameBloc` (gameModel present), `TimerBloc`, `AppBloc` (user id 'host'), `PlayerRepository`, and a real `GameOverBloc` built with: one slot linked to 'friend1', one linked to 'host', one unlinked. Assertions:
  - the account-owner dropdown's items do NOT include the friend-linked player's name but DO include the unlinked player, the host-linked player, and the `notPlayingOption` label;
  - the friend-linked standings row shows the linked badge icon (`byIcon(Icons.link_rounded)` finds at least one);
  - the dropdown preselects the host-linked slot (its name appears as the dropdown's current value).
Follow the repo's existing widget-test helpers (look at any existing test under `test/` that pumps a page with `MaterialApp` + `flutter_localizations`; reuse its pump helper if one exists).

- [ ] **Step 3: RED.** `flutter test test/life_counter/view/game_over_page_test.dart`.

- [ ] **Step 4: Implement in `game_over_page.dart`.**

In `_DetailsPanel`, replace the account-owner `_PlayerDropdown` (lines ~644-649) with a dedicated dropdown that filters and appends the sentinel:

```dart
          _AccountOwnerDropdown(
            value: state.selectedPlayerId,
            players: players,
            currentUserId: context.read<AppBloc>().state.user.id,
            onChanged: (v) =>
                context.read<GameOverBloc>().add(UpdateSelectedPlayerEvent(v)),
          ),
```

New widget (place near `_PlayerDropdown`, reusing its decoration verbatim):

```dart
class _AccountOwnerDropdown extends StatelessWidget {
  const _AccountOwnerDropdown({
    required this.value,
    required this.players,
    required this.currentUserId,
    required this.onChanged,
  });

  final String? value;
  final List<Player> players;
  final String currentUserId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectable = players
        .where(
          (p) => p.firebaseId == null || p.firebaseId == currentUserId,
        )
        .toList();
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: _MC.surfaceRaised,
      style: const TextStyle(
        color: _MC.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      iconEnabledColor: _MC.textSecondary,
      decoration: /* copy the InputDecoration from _PlayerDropdown verbatim */,
      items: [
        ...selectable.map(
          (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
        ),
        DropdownMenuItem(
          value: GameOverBloc.notPlayingId,
          child: Text(context.l10n.notPlayingOption),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
```

In `_StandingRow`, after the player/commander name column (before the drag handle), add the badge:

```dart
              if (player.firebaseId != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: context.l10n.linkedAccountBadge,
                    child: const Icon(
                      Icons.link_rounded,
                      color: _MC.accent,
                      size: 16,
                    ),
                  ),
                ),
```

- [ ] **Step 5: GREEN.** `flutter test test/life_counter && flutter test && flutter analyze` (full suite once — this task closes the phase's client work).

- [ ] **Step 6: Commit.**

```bash
git add lib/life_counter lib/l10n test/life_counter
git commit -m "feat: game-over account picker excludes linked slots, adds not-playing and linked badges"
```

---

### Task 8: Verification + INDEX update

**Files:**
- Modify: `docs/superpowers/plans/2026-07-03-friends-INDEX.md`

**Interfaces:** consumes everything above; produces the Plan B closure record.

- [ ] **Step 1: Full verification suite**

```bash
flutter analyze
flutter test
cd packages/firebase_database_repository && flutter test && cd ../..
cd functions && npm run build && npm test && cd ..
npx firebase-tools@14.9.0 emulators:exec --only firestore "npm --prefix functions run test:rules"
```

All green; analyze at baseline.

- [ ] **Step 2: INDEX update.** Mark Plan B's row `complete` (file name `2026-07-03-friends-b-gate-and-sync.md`); move the satisfied "Plan B must own" items into a "Resolved in Plan B" list (hasPin self-heal, PinNotSet, TRANSITIONAL header, isComplete gate, matches tightening, overwrite guard); extend the DEPLOY GATE with: **this plan's rules tightening and the app's fan-out removal MUST deploy together with the `onGameCreated` function** — deploying rules without the function (or shipping the app without deploying either) silently stops friends' match-history sync; the force-upgrade pairing decision (old clients break against migrated PINs and denied cross-user match writes once rules deploy) is Josh's call at release time.

- [ ] **Step 3: Commit.**

```bash
git add docs/superpowers/plans/2026-07-03-friends-INDEX.md docs/superpowers/plans/2026-07-03-friends-b-gate-and-sync.md
git commit -m "chore: verify friends plan B; update index and deploy gate"
```
