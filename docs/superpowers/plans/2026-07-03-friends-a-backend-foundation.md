# Friends Plan A: Backend Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the Firebase backend (Cloud Functions + versioned Firestore rules + emulator), move PIN hashes into an owner-only private doc, and switch client PIN validation to a rate-limited callable.

**Architecture:** Spec phase 1 of `docs/superpowers/specs/2026-07-03-friends-feature-design.md`. PIN hashes move from the world-readable `users/{uid}` doc to `users/{uid}/private/credentials` (owner-only rules), lazily migrated on login. A `validatePin` callable — the one job rules can't do — compares the secret server-side with a 5-failures→15-minute lockout per caller→target pair. Rules ship as a **transitional v1**: they lock down `private/**` and `pinAttempts/**` hard, but intentionally keep today's cross-user friend/match writes legal until Plans B/C move those flows.

**Tech Stack:** Firebase Cloud Functions v2 (TypeScript, Node 20, `firebase-functions` ^6, `firebase-admin` ^13, jest + ts-jest), `@firebase/rules-unit-testing` for rules tests, Flutter client (`cloud_functions` ^5.2.0, `fake_cloud_firestore` ^3.1.0 for repo tests, existing `bloc_test`/`mocktail` patterns).

## Global Constraints

- Firebase project ID: `magic-yeti` (from `firebase.json`); no GoogleService config changes.
- PIN is exactly 4 numeric digits everywhere; lockout policy is exactly **5 failed attempts → 15-minute lockout** per caller→target pair.
- Salted hash format: `pinHash = sha256(salt + pin)` hex, `salt` = 16 random bytes hex; legacy format `sha256(pin)` with `salt: null` must keep validating until Plan D retires it.
- Only friends of the target may call `validatePin`; anonymous callers always rejected.
- v1 rules must NOT break existing client flows: friend-edge batch writes and host game fan-out stay legal until Plans B/C.
- Dart: `very_good_analysis` lints; models `@JsonSerializable(explicitToJson: true)`; run `dart run build_runner build --delete-conflicting-outputs` after model changes.
- All new user-facing strings added to BOTH `lib/l10n/arb/app_en.arb` and `app_es.arb`, then `flutter gen-l10n --arb-dir="lib/l10n/arb"`.
- Commit after every task; messages follow `feat:`/`test:`/`chore:` conventions seen in `git log`.
- Do not deploy to production from a task; Task 11 stages deployment as an explicit manual gate.

---

### Task 1: Firebase infra scaffold (functions package, emulator config, .firebaserc)

**Files:**
- Create: `.firebaserc`
- Modify: `firebase.json`
- Create: `functions/package.json`
- Create: `functions/tsconfig.json`
- Create: `functions/.gitignore`
- Create: `functions/src/index.ts`

**Interfaces:**
- Consumes: nothing (first task)
- Produces: `functions/` npm package with `npm run build`, `npm test`, `npm run test:rules` scripts; `firebase emulators:start` config with auth:9099, firestore:8080, functions:5001. Later tasks add files under `functions/src/` and export them from `functions/src/index.ts`.

- [ ] **Step 1: Create `.firebaserc`**

```json
{
  "projects": {
    "default": "magic-yeti"
  }
}
```

- [ ] **Step 2: Rewrite `firebase.json`** (preserve the existing `flutter` block exactly; add `firestore`, `functions`, `emulators`):

```json
{
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "magic-yeti",
          "appId": "1:370172089725:android:8e686daa66153c82ad6814",
          "fileOutput": "android/app/google-services.json"
        }
      },
      "ios": {
        "default": {
          "projectId": "magic-yeti",
          "appId": "1:370172089725:ios:bf69e58694170008ad6814",
          "uploadDebugSymbols": false,
          "fileOutput": "ios/Runner/GoogleService-Info.plist"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "magic-yeti",
          "configurations": {
            "android": "1:370172089725:android:8e686daa66153c82ad6814",
            "ios": "1:370172089725:ios:bf69e58694170008ad6814"
          }
        }
      }
    }
  },
  "firestore": {
    "rules": "firestore.rules"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "predeploy": ["npm --prefix \"$RESOURCE_DIR\" run build"]
    }
  ],
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "functions": { "port": 5001 },
    "ui": { "enabled": true }
  }
}
```

Note: `firestore.rules` does not exist yet — Task 2 creates it TDD-style. Create an empty placeholder now so emulator commands don't fail:

```bash
cat > firestore.rules <<'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
EOF
```

- [ ] **Step 3: Create `functions/package.json`**

```json
{
  "name": "functions",
  "private": true,
  "engines": { "node": "20" },
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "test": "jest --testPathIgnorePatterns test/rules",
    "test:rules": "jest test/rules",
    "serve": "npm run build && firebase emulators:start --only functions,firestore,auth"
  },
  "dependencies": {
    "firebase-admin": "^13.0.0",
    "firebase-functions": "^6.1.0"
  },
  "devDependencies": {
    "@firebase/rules-unit-testing": "^4.0.0",
    "@types/jest": "^29.5.0",
    "@types/node": "^20.0.0",
    "firebase-functions-test": "^3.3.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.2.0",
    "typescript": "^5.5.0"
  },
  "jest": {
    "preset": "ts-jest",
    "testEnvironment": "node",
    "roots": ["<rootDir>/test"]
  }
}
```

- [ ] **Step 4: Create `functions/tsconfig.json`**

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "es2022",
    "lib": ["es2022"],
    "outDir": "lib",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "sourceMap": true
  },
  "include": ["src"]
}
```

- [ ] **Step 5: Create `functions/.gitignore`**

```
node_modules/
lib/
*.log
```

- [ ] **Step 6: Create `functions/src/index.ts`** (empty export barrel for now)

```typescript
// Cloud Functions entry point. Each function lives in its own module and
// is re-exported here so the Firebase CLI discovers it.
export {};
```

- [ ] **Step 7: Verify the scaffold builds**

Run: `cd functions && npm install && npm run build`
Expected: exits 0, `functions/lib/index.js` exists.

Run: `npx firebase-tools --version || firebase --version`
Expected: a version prints. If the CLI is missing, install with `npm install -g firebase-tools` (or use `npx firebase-tools` for all later `firebase` commands).

- [ ] **Step 8: Commit**

```bash
git add .firebaserc firebase.json firestore.rules functions/
git commit -m "chore: scaffold Cloud Functions package and Firebase emulator config"
```

---

### Task 2: Firestore rules v1 (TDD via rules-unit-testing)

**Files:**
- Create: `functions/test/rules/firestore-rules.test.ts`
- Modify: `firestore.rules` (replace the Task 1 placeholder)

**Interfaces:**
- Consumes: emulator config from Task 1.
- Produces: v1 rules contract relied on by all later plans — `users/{uid}/private/**` owner-only, `pinAttempts/**` no client access, `users/{uid}` writes owner-only, `users/{uid}/matches/{id}` reads owner-only (writes transitional-open), `games` update/delete host-only, `friendRequests` reads scoped to participants.

- [ ] **Step 1: Write the failing rules tests** — `functions/test/rules/firestore-rules.test.ts`:

```typescript
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'magic-yeti-rules-test',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();
const anon = () => env.unauthenticatedContext().firestore();

describe('private credentials', () => {
  test('owner can read and write own credentials', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users/alice/private/credentials'), {
        pinHash: 'h',
        salt: 's',
      }),
    );
    await assertSucceeds(
      getDoc(doc(alice(), 'users/alice/private/credentials')),
    );
  });

  test('another signed-in user cannot read or write credentials', async () => {
    await assertFails(getDoc(doc(bob(), 'users/alice/private/credentials')));
    await assertFails(
      setDoc(doc(bob(), 'users/alice/private/credentials'), { pinHash: 'x' }),
    );
  });
});

describe('pinAttempts', () => {
  test('no client may read or write pinAttempts', async () => {
    await assertFails(getDoc(doc(alice(), 'pinAttempts/alice_bob')));
    await assertFails(
      setDoc(doc(alice(), 'pinAttempts/alice_bob'), { failCount: 0 }),
    );
  });
});

describe('users', () => {
  test('any signed-in user can read a profile; anon cannot', async () => {
    await assertSucceeds(getDoc(doc(bob(), 'users/alice')));
    await assertFails(getDoc(doc(anon(), 'users/alice')));
  });

  test('only the owner can write their profile doc', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users/alice'), { username: 'alice' }),
    );
    await assertFails(setDoc(doc(bob(), 'users/alice'), { username: 'evil' }));
  });
});

describe('matches', () => {
  test('owner can read own matches; others cannot', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/alice/matches/g1'), { id: 'g1' });
    });
    await assertSucceeds(getDoc(doc(alice(), 'users/alice/matches/g1')));
    await assertFails(getDoc(doc(bob(), 'users/alice/matches/g1')));
  });

  test('TRANSITIONAL: another signed-in user may write matches (host fan-out until Plan B)', async () => {
    await assertSucceeds(
      setDoc(doc(bob(), 'users/alice/matches/g2'), { id: 'g2' }),
    );
  });
});

describe('games', () => {
  test('signed-in users can create and read games', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'games/g1'), { hostId: 'alice', roomId: 'AB2C' }),
    );
    await assertSucceeds(getDoc(doc(bob(), 'games/g1')));
  });

  test('only the host can update or delete a game', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'games/g1'), { hostId: 'alice' });
    });
    await assertSucceeds(updateDoc(doc(alice(), 'games/g1'), { x: 1 }));
    await assertFails(updateDoc(doc(bob(), 'games/g1'), { x: 2 }));
    await assertFails(deleteDoc(doc(bob(), 'games/g1')));
  });
});

describe('friends (TRANSITIONAL until Plan C)', () => {
  test('owner reads own friend list; non-participant cannot', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friends/alice/friendList/bob'), {
        userId: 'bob',
      });
    });
    await assertSucceeds(getDoc(doc(alice(), 'friends/alice/friendList/bob')));
    await assertFails(getDoc(doc(bob(), 'friends/alice/friendList/bob')));
  });

  test('TRANSITIONAL: signed-in users may write friend edges (accept batch until Plan C)', async () => {
    await assertSucceeds(
      setDoc(doc(bob(), 'friends/alice/friendList/bob'), { userId: 'bob' }),
    );
  });
});

describe('friendRequests', () => {
  test('participants can read; strangers cannot', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friendRequests/r1'), {
        senderId: 'alice',
        receiverId: 'bob',
        status: 'pending',
      });
    });
    await assertSucceeds(getDoc(doc(alice(), 'friendRequests/r1')));
    await assertSucceeds(getDoc(doc(bob(), 'friendRequests/r1')));
    await assertFails(
      getDoc(doc(env.authenticatedContext('carol').firestore(), 'friendRequests/r1')),
    );
  });

  test('sender may create a request as themselves only', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'friendRequests/r2'), {
        senderId: 'alice',
        receiverId: 'bob',
        status: 'pending',
      }),
    );
    await assertFails(
      setDoc(doc(alice(), 'friendRequests/r3'), {
        senderId: 'bob',
        receiverId: 'carol',
        status: 'pending',
      }),
    );
  });
});
```

Also add the `firebase` web SDK needed by the test file: in `functions/package.json` devDependencies add `"firebase": "^10.12.0"`, then `cd functions && npm install`.

- [ ] **Step 2: Run rules tests to verify they fail against the placeholder rules**

Run: `firebase emulators:exec --only firestore "npm --prefix functions run test:rules"`
Expected: FAIL — private-credentials isolation and pinAttempts tests fail (placeholder allows all signed-in access).

- [ ] **Step 3: Write the real `firestore.rules`** (replace placeholder entirely):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }
    function isOwner(uid) {
      return signedIn() && request.auth.uid == uid;
    }

    match /users/{uid} {
      allow read: if signedIn();
      allow write: if isOwner(uid);

      match /private/{document=**} {
        allow read, write: if isOwner(uid);
      }

      match /matches/{gameId} {
        allow read: if isOwner(uid);
        // TRANSITIONAL (Plan B removes): host client fan-out writes cross-user.
        allow write: if signedIn();
      }
    }

    // Server-only rate limiting state. No client access, ever.
    match /pinAttempts/{attemptId} {
      allow read, write: if false;
    }

    match /games/{gameId} {
      allow read, create: if signedIn();
      allow update, delete: if signedIn() && resource.data.hostId == request.auth.uid;
    }

    match /friends/{uid}/friendList/{friendId} {
      allow read: if isOwner(uid);
      // TRANSITIONAL (Plan C tightens): accept/remove batch writes cross-user.
      allow write: if signedIn();
    }

    match /friendRequests/{requestId} {
      allow read: if signedIn() &&
        (resource.data.senderId == request.auth.uid ||
         resource.data.receiverId == request.auth.uid);
      allow create: if signedIn() &&
        request.resource.data.senderId == request.auth.uid;
      // TRANSITIONAL (Plan C tightens to deterministic-ID lifecycle rules).
      allow update, delete: if signedIn() &&
        (resource.data.senderId == request.auth.uid ||
         resource.data.receiverId == request.auth.uid);
    }
  }
}
```

- [ ] **Step 4: Run rules tests to verify they pass**

Run: `firebase emulators:exec --only firestore "npm --prefix functions run test:rules"`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add firestore.rules functions/test/rules/firestore-rules.test.ts functions/package.json functions/package-lock.json
git commit -m "feat: versioned Firestore rules v1 with private-credentials lockdown and rules tests"
```

---

### Task 3: Pure PIN logic module in functions (TDD)

**Files:**
- Create: `functions/src/pin-logic.ts`
- Create: `functions/test/pin-logic.test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces (used by Task 4):
  - `hashPin(pin: string): string` — sha256 hex of pin (legacy format)
  - `saltedPinHash(pin: string, salt: string): string` — sha256 hex of `salt + pin`
  - `checkPin(stored: StoredCredentials, pin: string): boolean` where `StoredCredentials = { pinHash: string; salt: string | null }`
  - `MAX_ATTEMPTS = 5`, `LOCKOUT_MS = 15 * 60 * 1000`
  - `evaluateAttempt(state: AttemptState | null, nowMillis: number): { lockedOut: boolean; lockedUntilMillis: number | null }` where `AttemptState = { failCount: number; lockedUntilMillis: number | null }`
  - `recordFailure(state: AttemptState | null, nowMillis: number): AttemptState` — increments; sets `lockedUntilMillis = now + LOCKOUT_MS` when the new count reaches `MAX_ATTEMPTS`; a failure after an expired lockout starts a fresh count of 1.

- [ ] **Step 1: Write the failing test** — `functions/test/pin-logic.test.ts`:

```typescript
import {
  hashPin,
  saltedPinHash,
  checkPin,
  evaluateAttempt,
  recordFailure,
  MAX_ATTEMPTS,
  LOCKOUT_MS,
} from '../src/pin-logic';

describe('hashing', () => {
  test('hashPin matches known sha256 of "0742"', () => {
    // echo -n 0742 | shasum -a 256
    expect(hashPin('0742')).toBe(
      'bfe0891a5e7a17a4d51bee79fbde07572ac3057c1a7ab164136dfd68f5a20d6a',
    );
  });

  test('salted hash differs from unsalted and is stable', () => {
    const salted = saltedPinHash('0742', 'abc123');
    expect(salted).not.toBe(hashPin('0742'));
    expect(saltedPinHash('0742', 'abc123')).toBe(salted);
  });
});

describe('checkPin', () => {
  test('legacy credentials (salt null) validate with plain hash', () => {
    expect(checkPin({ pinHash: hashPin('1234'), salt: null }, '1234')).toBe(true);
    expect(checkPin({ pinHash: hashPin('1234'), salt: null }, '4321')).toBe(false);
  });

  test('salted credentials validate with salted hash', () => {
    const stored = { pinHash: saltedPinHash('1234', 's4lt'), salt: 's4lt' };
    expect(checkPin(stored, '1234')).toBe(true);
    expect(checkPin(stored, '0000')).toBe(false);
  });
});

describe('lockout state machine', () => {
  const NOW = 1_000_000;

  test('null state is not locked out', () => {
    expect(evaluateAttempt(null, NOW)).toEqual({
      lockedOut: false,
      lockedUntilMillis: null,
    });
  });

  test('recordFailure increments and locks at MAX_ATTEMPTS', () => {
    let state = recordFailure(null, NOW); // 1
    for (let i = 1; i < MAX_ATTEMPTS - 1; i++) state = recordFailure(state, NOW);
    expect(state.failCount).toBe(MAX_ATTEMPTS - 1);
    expect(state.lockedUntilMillis).toBeNull();

    state = recordFailure(state, NOW); // 5th failure
    expect(state.failCount).toBe(MAX_ATTEMPTS);
    expect(state.lockedUntilMillis).toBe(NOW + LOCKOUT_MS);
    expect(evaluateAttempt(state, NOW + 1).lockedOut).toBe(true);
  });

  test('lockout expires and a new failure starts a fresh count', () => {
    const locked = { failCount: 5, lockedUntilMillis: NOW + LOCKOUT_MS };
    const after = NOW + LOCKOUT_MS + 1;
    expect(evaluateAttempt(locked, after).lockedOut).toBe(false);
    expect(recordFailure(locked, after)).toEqual({
      failCount: 1,
      lockedUntilMillis: null,
    });
  });
});
```

- [ ] **Step 2: Run to verify failure**

Run: `cd functions && npm test`
Expected: FAIL — `Cannot find module '../src/pin-logic'`.

- [ ] **Step 3: Implement `functions/src/pin-logic.ts`**

```typescript
import { createHash } from 'crypto';

export const MAX_ATTEMPTS = 5;
export const LOCKOUT_MS = 15 * 60 * 1000;

export interface StoredCredentials {
  pinHash: string;
  salt: string | null;
}

export interface AttemptState {
  failCount: number;
  lockedUntilMillis: number | null;
}

export function hashPin(pin: string): string {
  return createHash('sha256').update(pin).digest('hex');
}

export function saltedPinHash(pin: string, salt: string): string {
  return createHash('sha256').update(salt + pin).digest('hex');
}

export function checkPin(stored: StoredCredentials, pin: string): boolean {
  const expected =
    stored.salt === null ? hashPin(pin) : saltedPinHash(pin, stored.salt);
  return stored.pinHash === expected;
}

export function evaluateAttempt(
  state: AttemptState | null,
  nowMillis: number,
): { lockedOut: boolean; lockedUntilMillis: number | null } {
  if (
    state?.lockedUntilMillis != null &&
    state.lockedUntilMillis > nowMillis
  ) {
    return { lockedOut: true, lockedUntilMillis: state.lockedUntilMillis };
  }
  return { lockedOut: false, lockedUntilMillis: null };
}

export function recordFailure(
  state: AttemptState | null,
  nowMillis: number,
): AttemptState {
  const lockoutExpired =
    state?.lockedUntilMillis != null && state.lockedUntilMillis <= nowMillis;
  const previousCount = state === null || lockoutExpired ? 0 : state.failCount;
  const failCount = previousCount + 1;
  return {
    failCount,
    lockedUntilMillis: failCount >= MAX_ATTEMPTS ? nowMillis + LOCKOUT_MS : null,
  };
}
```

- [ ] **Step 4: Run to verify pass**

Run: `cd functions && npm test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add functions/src/pin-logic.ts functions/test/pin-logic.test.ts
git commit -m "feat: pure PIN hashing and lockout logic for Cloud Functions"
```

---

### Task 4: `validatePin` callable (emulator-integration TDD)

**Files:**
- Create: `functions/src/validate-pin.ts`
- Modify: `functions/src/index.ts`
- Create: `functions/test/rules/validate-pin.integration.test.ts` (lives under `test/rules/` so it runs inside `emulators:exec` with Firestore available)

**Interfaces:**
- Consumes: Task 3's `checkPin`, `evaluateAttempt`, `recordFailure`, `MAX_ATTEMPTS`.
- Produces the callable contract the Dart client (Task 7) depends on:
  - Callable name: **`validatePin`**; request `{ targetUserId: string, pin: string }`
  - Success: `{ valid: true }` or `{ valid: false, attemptsRemaining: number }`
  - Errors: `unauthenticated`; `permission-denied` (anonymous caller or caller not on target's friend list); `invalid-argument` (pin not 4 digits / missing target); `failed-precondition` (target has no PIN); `resource-exhausted` with `details.lockedUntilMillis` (locked out)
  - Firestore side effects: reads `users/{target}/private/credentials` falling back to `users/{target}.pin`; transactionally maintains `pinAttempts/{callerUid}_{targetUid}` `{ failCount, lockedUntilMillis, updatedAt }`; deletes the attempts doc on success.

- [ ] **Step 1: Write the failing integration test** — `functions/test/rules/validate-pin.integration.test.ts`:

```typescript
/**
 * Runs inside `firebase emulators:exec --only firestore` via the test:rules
 * script. Uses firebase-functions-test in online mode against the emulator.
 */
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.GCLOUD_PROJECT = 'magic-yeti-fn-test';

import functionsTest from 'firebase-functions-test';
import * as admin from 'firebase-admin';
import { hashPin, saltedPinHash, MAX_ATTEMPTS } from '../../src/pin-logic';

const testEnv = functionsTest({ projectId: 'magic-yeti-fn-test' });
// Import AFTER functionsTest() so admin.initializeApp inside the module
// picks up emulator env.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { validatePin } = require('../../src/validate-pin');

const db = admin.firestore();
const wrapped = testEnv.wrap(validatePin);

const callerAuth = {
  uid: 'caller',
  token: { firebase: { sign_in_provider: 'password' } },
};

async function seedFriendshipAndPin(opts: { salted: boolean }) {
  await db.doc('friends/target/friendList/caller').set({ userId: 'caller' });
  if (opts.salted) {
    await db.doc('users/target/private/credentials').set({
      pinHash: saltedPinHash('0742', 'somesalt'),
      salt: 'somesalt',
    });
  } else {
    await db.doc('users/target').set({ pin: hashPin('0742') });
  }
}

afterAll(async () => {
  testEnv.cleanup();
});

beforeEach(async () => {
  const collections = await db.listCollections();
  await Promise.all(
    collections.map((c) => db.recursiveDelete(c)),
  );
});

test('correct PIN against salted credentials returns valid', async () => {
  await seedFriendshipAndPin({ salted: true });
  const result = await wrapped({
    data: { targetUserId: 'target', pin: '0742' },
    auth: callerAuth,
  });
  expect(result).toEqual({ valid: true });
});

test('correct PIN against legacy profile field returns valid (fallback)', async () => {
  await seedFriendshipAndPin({ salted: false });
  const result = await wrapped({
    data: { targetUserId: 'target', pin: '0742' },
    auth: callerAuth,
  });
  expect(result).toEqual({ valid: true });
});

test('wrong PIN decrements attempts and locks out after MAX_ATTEMPTS', async () => {
  await seedFriendshipAndPin({ salted: true });
  for (let i = 1; i < MAX_ATTEMPTS; i++) {
    const r = await wrapped({
      data: { targetUserId: 'target', pin: '9999' },
      auth: callerAuth,
    });
    expect(r.valid).toBe(false);
    expect(r.attemptsRemaining).toBe(MAX_ATTEMPTS - i);
  }
  // 5th failure locks
  const fifth = await wrapped({
    data: { targetUserId: 'target', pin: '9999' },
    auth: callerAuth,
  });
  expect(fifth.valid).toBe(false);
  expect(fifth.attemptsRemaining).toBe(0);

  // 6th attempt — even with the CORRECT pin — is locked out
  await expect(
    wrapped({ data: { targetUserId: 'target', pin: '0742' }, auth: callerAuth }),
  ).rejects.toMatchObject({ code: 'resource-exhausted' });
});

test('success clears the attempt counter', async () => {
  await seedFriendshipAndPin({ salted: true });
  await wrapped({ data: { targetUserId: 'target', pin: '9999' }, auth: callerAuth });
  await wrapped({ data: { targetUserId: 'target', pin: '0742' }, auth: callerAuth });
  const attempts = await db.doc('pinAttempts/caller_target').get();
  expect(attempts.exists).toBe(false);
});

test('non-friend caller is rejected', async () => {
  await db.doc('users/target/private/credentials').set({
    pinHash: saltedPinHash('0742', 's'),
    salt: 's',
  });
  await expect(
    wrapped({ data: { targetUserId: 'target', pin: '0742' }, auth: callerAuth }),
  ).rejects.toMatchObject({ code: 'permission-denied' });
});

test('anonymous caller is rejected', async () => {
  await seedFriendshipAndPin({ salted: true });
  await expect(
    wrapped({
      data: { targetUserId: 'target', pin: '0742' },
      auth: {
        uid: 'caller',
        token: { firebase: { sign_in_provider: 'anonymous' } },
      },
    }),
  ).rejects.toMatchObject({ code: 'permission-denied' });
});

test('missing auth is rejected', async () => {
  await expect(
    wrapped({ data: { targetUserId: 'target', pin: '0742' } }),
  ).rejects.toMatchObject({ code: 'unauthenticated' });
});

test('malformed pin is rejected', async () => {
  await seedFriendshipAndPin({ salted: true });
  await expect(
    wrapped({ data: { targetUserId: 'target', pin: '12' }, auth: callerAuth }),
  ).rejects.toMatchObject({ code: 'invalid-argument' });
});

test('target without any PIN yields failed-precondition', async () => {
  await db.doc('friends/target/friendList/caller').set({ userId: 'caller' });
  await expect(
    wrapped({ data: { targetUserId: 'target', pin: '0742' }, auth: callerAuth }),
  ).rejects.toMatchObject({ code: 'failed-precondition' });
});
```

- [ ] **Step 2: Run to verify failure**

Run: `cd functions && npm run build && cd .. && firebase emulators:exec --only firestore "npm --prefix functions run test:rules"`
Expected: FAIL — `Cannot find module '../../src/validate-pin'`.

- [ ] **Step 3: Implement `functions/src/validate-pin.ts`**

```typescript
import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  AttemptState,
  checkPin,
  evaluateAttempt,
  MAX_ATTEMPTS,
  recordFailure,
  StoredCredentials,
} from './pin-logic';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface ValidatePinRequest {
  targetUserId?: string;
  pin?: string;
}

export const validatePin = onCall<ValidatePinRequest>(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  if (auth.token?.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Anonymous users cannot validate PINs.');
  }

  const { targetUserId, pin } = request.data ?? {};
  if (typeof targetUserId !== 'string' || targetUserId.length === 0) {
    throw new HttpsError('invalid-argument', 'targetUserId is required.');
  }
  if (typeof pin !== 'string' || !/^\d{4}$/.test(pin)) {
    throw new HttpsError('invalid-argument', 'pin must be exactly 4 digits.');
  }

  const db = admin.firestore();
  const callerUid = auth.uid;

  // Only friends of the target may attempt validation.
  const friendEdge = await db
    .doc(`friends/${targetUserId}/friendList/${callerUid}`)
    .get();
  if (!friendEdge.exists) {
    throw new HttpsError('permission-denied', 'Caller is not a friend of the target.');
  }

  // Load stored credentials: private doc first, legacy profile field fallback.
  let stored: StoredCredentials | null = null;
  const credentials = await db
    .doc(`users/${targetUserId}/private/credentials`)
    .get();
  if (credentials.exists) {
    const data = credentials.data()!;
    stored = {
      pinHash: data.pinHash as string,
      salt: (data.salt as string | null) ?? null,
    };
  } else {
    const profile = await db.doc(`users/${targetUserId}`).get();
    const legacyHash = profile.data()?.pin as string | undefined;
    if (legacyHash != null && legacyHash.length > 0) {
      stored = { pinHash: legacyHash, salt: null };
    }
  }
  if (stored === null) {
    throw new HttpsError('failed-precondition', 'Target user has no PIN set.');
  }

  const attemptsRef = db.doc(`pinAttempts/${callerUid}_${targetUserId}`);

  return db.runTransaction(async (tx) => {
    const now = Date.now();
    const attemptsSnap = await tx.get(attemptsRef);
    const state: AttemptState | null = attemptsSnap.exists
      ? {
          failCount: attemptsSnap.data()!.failCount as number,
          lockedUntilMillis:
            (attemptsSnap.data()!.lockedUntilMillis as number | null) ?? null,
        }
      : null;

    const lock = evaluateAttempt(state, now);
    if (lock.lockedOut) {
      throw new HttpsError('resource-exhausted', 'Too many failed attempts.', {
        lockedUntilMillis: lock.lockedUntilMillis,
      });
    }

    if (checkPin(stored!, pin)) {
      if (attemptsSnap.exists) {
        tx.delete(attemptsRef);
      }
      return { valid: true };
    }

    const next = recordFailure(state, now);
    tx.set(attemptsRef, {
      failCount: next.failCount,
      lockedUntilMillis: next.lockedUntilMillis,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {
      valid: false,
      attemptsRemaining: Math.max(0, MAX_ATTEMPTS - next.failCount),
    };
  });
});
```

- [ ] **Step 4: Export from `functions/src/index.ts`** (replace file contents):

```typescript
// Cloud Functions entry point. Each function lives in its own module and
// is re-exported here so the Firebase CLI discovers it.
export { validatePin } from './validate-pin';
```

- [ ] **Step 5: Build and run integration tests**

Run: `cd functions && npm run build && cd .. && firebase emulators:exec --only firestore "npm --prefix functions run test:rules"`
Expected: PASS — all validate-pin integration tests and the Task 2 rules tests.

- [ ] **Step 6: Commit**

```bash
git add functions/src/validate-pin.ts functions/src/index.ts functions/test/rules/validate-pin.integration.test.ts
git commit -m "feat: rate-limited validatePin callable with friend gating and legacy fallback"
```

---

### Task 5: Dart models — `PinValidationResult` + `UserProfileModel.hasPin`

**Files:**
- Create: `packages/firebase_database_repository/lib/models/pin_validation_result.dart`
- Modify: `packages/firebase_database_repository/lib/models/user_profile_model.dart`
- Modify: `packages/firebase_database_repository/lib/models/models.dart` (add export)
- Create: `packages/firebase_database_repository/test/models/pin_validation_result_test.dart`
- Create: `packages/firebase_database_repository/test/models/user_profile_model_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces (used by Tasks 6–10 and Plans B–D):
  - `sealed class PinValidationResult` with subtypes `PinValid()`, `PinInvalid({required int attemptsRemaining})`, `PinLockedOut({required DateTime lockedUntil})`, `PinCheckUnavailable()` — all `const`, all `Equatable`.
  - `UserProfileModel.hasPin` (`bool`, default `false`, serialized as `hasPin`).
  - `UserProfileModel.isComplete` getter: `onboardingComplete && (username?.isNotEmpty ?? false) && (hasPin || (pin?.isNotEmpty ?? false))`.

- [ ] **Step 1: Write failing model tests** — `packages/firebase_database_repository/test/models/pin_validation_result_test.dart`:

```dart
import 'package:firebase_database_repository/models/models.dart';
import 'package:test/test.dart';

void main() {
  group('PinValidationResult', () {
    test('value equality', () {
      expect(const PinValid(), const PinValid());
      expect(
        const PinInvalid(attemptsRemaining: 3),
        const PinInvalid(attemptsRemaining: 3),
      );
      expect(
        const PinInvalid(attemptsRemaining: 3),
        isNot(const PinInvalid(attemptsRemaining: 2)),
      );
      expect(
        PinLockedOut(lockedUntil: DateTime.utc(2026, 7, 3)),
        PinLockedOut(lockedUntil: DateTime.utc(2026, 7, 3)),
      );
      expect(const PinCheckUnavailable(), const PinCheckUnavailable());
    });

    test('subtypes are exhaustively switchable', () {
      String describe(PinValidationResult r) => switch (r) {
            PinValid() => 'valid',
            PinInvalid(:final attemptsRemaining) => 'invalid:$attemptsRemaining',
            PinLockedOut() => 'locked',
            PinCheckUnavailable() => 'unavailable',
          };
      expect(describe(const PinValid()), 'valid');
      expect(describe(const PinInvalid(attemptsRemaining: 2)), 'invalid:2');
    });
  });
}
```

And `packages/firebase_database_repository/test/models/user_profile_model_test.dart`:

```dart
import 'package:firebase_database_repository/models/models.dart';
import 'package:test/test.dart';

void main() {
  group('UserProfileModel', () {
    test('hasPin defaults false and round-trips through json', () {
      const model = UserProfileModel(id: 'u1', hasPin: true);
      final decoded = UserProfileModel.fromJson(model.toJson());
      expect(decoded.hasPin, isTrue);
      expect(UserProfileModel.fromJson(const {'id': 'u2'}).hasPin, isFalse);
    });

    group('isComplete', () {
      test('true when onboarded with username and hasPin', () {
        const m = UserProfileModel(
          id: 'u',
          username: 'josh',
          hasPin: true,
          onboardingComplete: true,
        );
        expect(m.isComplete, isTrue);
      });

      test('legacy unmigrated pin field counts as having a PIN', () {
        const m = UserProfileModel(
          id: 'u',
          username: 'josh',
          pin: 'somelegacyhash',
          onboardingComplete: true,
        );
        expect(m.isComplete, isTrue);
      });

      test('false when missing username, PIN, or onboarding flag', () {
        const base = UserProfileModel(
          id: 'u',
          username: 'josh',
          hasPin: true,
          onboardingComplete: true,
        );
        expect(base.copyWith(username: '').isComplete, isFalse);
        expect(
          const UserProfileModel(
            id: 'u',
            username: 'josh',
            onboardingComplete: true,
          ).isComplete,
          isFalse,
        );
        expect(base.copyWith(onboardingComplete: false).isComplete, isFalse);
      });
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd packages/firebase_database_repository && flutter test test/models`
Expected: FAIL — `PinValidationResult` undefined, `hasPin` undefined.

- [ ] **Step 3: Implement.** Create `packages/firebase_database_repository/lib/models/pin_validation_result.dart`:

```dart
import 'package:equatable/equatable.dart';

/// {@template pin_validation_result}
/// Result of validating a friend's PIN via the `validatePin` callable.
/// {@endtemplate}
sealed class PinValidationResult extends Equatable {
  /// {@macro pin_validation_result}
  const PinValidationResult();

  @override
  List<Object?> get props => [];
}

/// The PIN was correct.
final class PinValid extends PinValidationResult {
  /// Creates a valid result.
  const PinValid();
}

/// The PIN was wrong; [attemptsRemaining] tries left before lockout.
final class PinInvalid extends PinValidationResult {
  /// Creates an invalid result.
  const PinInvalid({required this.attemptsRemaining});

  /// Attempts left before a lockout is applied.
  final int attemptsRemaining;

  @override
  List<Object?> get props => [attemptsRemaining];
}

/// Too many failed attempts; retry after [lockedUntil].
final class PinLockedOut extends PinValidationResult {
  /// Creates a locked-out result.
  const PinLockedOut({required this.lockedUntil});

  /// When the lockout expires.
  final DateTime lockedUntil;

  @override
  List<Object?> get props => [lockedUntil];
}

/// The check could not be performed (offline or server error).
final class PinCheckUnavailable extends PinValidationResult {
  /// Creates an unavailable result.
  const PinCheckUnavailable();
}
```

In `user_profile_model.dart`: add the field, constructor param (`this.hasPin = false`), `copyWith` support, `props` entry, and the getter:

```dart
  /// Whether the user has a PIN set (hash lives in the private
  /// credentials subcollection, so only this flag is public).
  final bool hasPin;

  /// Whether the profile satisfies the friends-feature requirements:
  /// onboarded, has a username, and has a PIN (new flag or legacy field).
  bool get isComplete =>
      onboardingComplete &&
      (username?.isNotEmpty ?? false) &&
      (hasPin || (pin?.isNotEmpty ?? false));
```

Add `export 'pin_validation_result.dart';` to `packages/firebase_database_repository/lib/models/models.dart`.

- [ ] **Step 4: Regenerate JSON code and run tests**

Run: `cd packages/firebase_database_repository && dart run build_runner build --delete-conflicting-outputs && flutter test test/models`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/firebase_database_repository/lib packages/firebase_database_repository/test
git commit -m "feat: PinValidationResult model and UserProfileModel.hasPin/isComplete"
```

---

### Task 6: Repository — salted `setPin`, `migrateLegacyPin`, updated `hasPin`

**Files:**
- Modify: `packages/firebase_database_repository/pubspec.yaml` (add `fake_cloud_firestore: ^3.1.0` to dev_dependencies)
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart`
- Create: `packages/firebase_database_repository/test/src/pin_storage_test.dart`

**Interfaces:**
- Consumes: Task 5 models.
- Produces (used by Tasks 8–10 and Plan B):
  - `static String generateSalt()` — 16 random bytes hex (32 chars)
  - `static String saltedPinHash(String pin, String salt)` — sha256 hex of `salt + pin`
  - `Future<void> setPin(String userId, String pin)` — writes `users/{uid}/private/credentials` `{pinHash, salt, updatedAt}`, merges `{'hasPin': true}` into `users/{uid}`, deletes legacy `pin` field
  - `Future<void> migrateLegacyPin(String userId)` — no-op unless `users/{uid}.pin` is a non-empty string and no private credentials doc exists; then copies it as `{pinHash: legacy, salt: null}`, sets `hasPin: true`, deletes the field
  - `Future<bool> hasPin(String userId)` — true when profile `hasPin == true` OR legacy `pin` non-empty
  - Existing `static String hashPin(String pin)` unchanged (legacy format).

- [ ] **Step 1: Add dev dependency.** In `packages/firebase_database_repository/pubspec.yaml` dev_dependencies add `fake_cloud_firestore: ^3.1.0`, then run `cd packages/firebase_database_repository && flutter pub get`.

- [ ] **Step 2: Write failing tests** — `packages/firebase_database_repository/test/src/pin_storage_test.dart`:

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

  group('salt helpers', () {
    test('generateSalt returns 32 hex chars and is random', () {
      final a = FirebaseDatabaseRepository.generateSalt();
      final b = FirebaseDatabaseRepository.generateSalt();
      expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(a, isNot(b));
    });

    test('saltedPinHash is deterministic and salt-sensitive', () {
      final h1 = FirebaseDatabaseRepository.saltedPinHash('0742', 'aa');
      expect(h1, FirebaseDatabaseRepository.saltedPinHash('0742', 'aa'));
      expect(h1, isNot(FirebaseDatabaseRepository.saltedPinHash('0742', 'bb')));
      expect(h1, isNot(FirebaseDatabaseRepository.hashPin('0742')));
    });
  });

  group('setPin', () {
    test('writes salted credentials, sets hasPin, removes legacy field',
        () async {
      await firestore
          .collection('users')
          .doc('u1')
          .set({'username': 'josh', 'pin': 'legacyhash'});

      await repository.setPin('u1', '0742');

      final creds = await firestore
          .doc('users/u1/private/credentials')
          .get();
      final salt = creds.data()!['salt'] as String;
      expect(
        creds.data()!['pinHash'],
        FirebaseDatabaseRepository.saltedPinHash('0742', salt),
      );

      final profile = await firestore.doc('users/u1').get();
      expect(profile.data()!['hasPin'], isTrue);
      expect(profile.data()!.containsKey('pin'), isFalse);
      expect(profile.data()!['username'], 'josh');
    });
  });

  group('migrateLegacyPin', () {
    test('moves legacy hash into private credentials with null salt',
        () async {
      final legacyHash = FirebaseDatabaseRepository.hashPin('0742');
      await firestore.collection('users').doc('u1').set({'pin': legacyHash});

      await repository.migrateLegacyPin('u1');

      final creds =
          await firestore.doc('users/u1/private/credentials').get();
      expect(creds.data()!['pinHash'], legacyHash);
      expect(creds.data()!['salt'], isNull);

      final profile = await firestore.doc('users/u1').get();
      expect(profile.data()!['hasPin'], isTrue);
      expect(profile.data()!.containsKey('pin'), isFalse);
    });

    test('no-ops when there is nothing to migrate', () async {
      await firestore.collection('users').doc('u1').set({'username': 'j'});
      await repository.migrateLegacyPin('u1');
      final creds =
          await firestore.doc('users/u1/private/credentials').get();
      expect(creds.exists, isFalse);
    });

    test('does not overwrite already-migrated credentials', () async {
      await firestore.doc('users/u1/private/credentials').set({
        'pinHash': 'saltedHash',
        'salt': 'realsalt',
      });
      await firestore
          .collection('users')
          .doc('u1')
          .set({'pin': 'staleLegacy'});

      await repository.migrateLegacyPin('u1');

      final creds =
          await firestore.doc('users/u1/private/credentials').get();
      expect(creds.data()!['pinHash'], 'saltedHash');
      final profile = await firestore.doc('users/u1').get();
      expect(profile.data()!.containsKey('pin'), isFalse);
      expect(profile.data()!['hasPin'], isTrue);
    });
  });

  group('hasPin', () {
    test('true for hasPin flag, true for legacy field, false otherwise',
        () async {
      await firestore.collection('users').doc('a').set({'hasPin': true});
      await firestore.collection('users').doc('b').set({'pin': 'hash'});
      await firestore.collection('users').doc('c').set({'username': 'x'});
      expect(await repository.hasPin('a'), isTrue);
      expect(await repository.hasPin('b'), isTrue);
      expect(await repository.hasPin('c'), isFalse);
    });
  });
}
```

- [ ] **Step 3: Run to verify failure**

Run: `cd packages/firebase_database_repository && flutter test test/src/pin_storage_test.dart`
Expected: FAIL — `generateSalt`/`saltedPinHash`/`migrateLegacyPin` undefined; `setPin` writes to the wrong place.

- [ ] **Step 4: Implement in `firebase_database_repository.dart`.** Replace the existing `setPin` (currently at the bottom of the class, writing `{'pin': hashPin(pin)}` to the profile) and the existing `hasPin`, and add the new members:

```dart
  /// Generates a random 16-byte hex salt for PIN hashing.
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes a PIN with a salt: sha256(salt + pin).
  static String saltedPinHash(String pin, String salt) {
    final bytes = utf8.encode(salt + pin);
    return sha256.convert(bytes).toString();
  }

  DocumentReference<Map<String, dynamic>> _credentialsDoc(String userId) =>
      _firebase.doc('users/$userId/private/credentials');

  /// Sets the user's PIN: salted hash into the private credentials doc,
  /// `hasPin` flag onto the profile, legacy `pin` field removed.
  Future<void> setPin(String userId, String pin) async {
    try {
      final salt = generateSalt();
      final batch = _firebase.batch()
        ..set(_credentialsDoc(userId), {
          'pinHash': saltedPinHash(pin, salt),
          'salt': salt,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        ..set(
          _firebase.collection('users').doc(userId),
          {'hasPin': true, 'pin': FieldValue.delete()},
          SetOptions(merge: true),
        );
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set PIN: $e');
    }
  }

  /// Moves a legacy profile-doc PIN hash into the private credentials
  /// doc. Safe to call on every login; no-ops when nothing to migrate.
  Future<void> migrateLegacyPin(String userId) async {
    try {
      final profileRef = _firebase.collection('users').doc(userId);
      final profile = await profileRef.get();
      if (!profile.exists) return;
      final legacyHash = profile.data()?['pin'] as String?;
      if (legacyHash == null || legacyHash.isEmpty) return;

      final credentials = await _credentialsDoc(userId).get();
      final batch = _firebase.batch();
      if (!credentials.exists) {
        batch.set(_credentialsDoc(userId), {
          'pinHash': legacyHash,
          'salt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      batch.set(
        profileRef,
        {'hasPin': true, 'pin': FieldValue.delete()},
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (_) {
      // Migration is best-effort on login; the callable's legacy
      // fallback keeps validation working until it succeeds.
    }
  }

  /// Checks whether a user has set their PIN (new flag or legacy field).
  Future<bool> hasPin(String userId) async {
    try {
      final doc = await _firebase.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final legacy = data['pin'] as String?;
      return data['hasPin'] == true || (legacy != null && legacy.isNotEmpty);
    } catch (e) {
      return false;
    }
  }
```

Note: the class constructor is `const`; adding these members keeps it const-compatible (no new instance fields yet — Task 7 adds the functions field).

- [ ] **Step 5: Run tests to verify pass**

Run: `cd packages/firebase_database_repository && flutter test`
Expected: PASS (new tests plus all pre-existing package tests).

- [ ] **Step 6: Commit**

```bash
git add packages/firebase_database_repository
git commit -m "feat: salted PIN storage in private credentials with lazy legacy migration"
```

---

### Task 7: Repository — `validatePin` becomes the callable

**Files:**
- Modify: `packages/firebase_database_repository/pubspec.yaml` (add `cloud_functions: ^5.2.0` to dependencies)
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` (constructor + `validatePin`)
- Modify: `lib/main_development.dart:21`, `lib/main_staging.dart:21`, `lib/main_production.dart:21`
- Modify: root `pubspec.yaml` (add `cloud_functions: ^5.2.0`)
- Create: `packages/firebase_database_repository/test/src/validate_pin_test.dart`

**Interfaces:**
- Consumes: Task 4's callable contract, Task 5's `PinValidationResult`.
- Produces (used by Task 8):
  - Constructor: `FirebaseDatabaseRepository({required FirebaseFirestore firebase, FirebaseFunctions? functions})` — `functions` optional so existing tests/constructions keep working; resolved lazily via `functions ?? FirebaseFunctions.instance`.
  - `Future<PinValidationResult> validatePin({required String targetUserId, required String pin})` — **named parameters, new signature** (old positional `validatePin(userId, pin) → bool` is deleted).

- [ ] **Step 1: Add dependencies.** `cloud_functions: ^5.2.0` in BOTH `packages/firebase_database_repository/pubspec.yaml` dependencies and the root `pubspec.yaml` dependencies. Run `flutter pub get` in both places.

- [ ] **Step 2: Write failing tests** — `packages/firebase_database_repository/test/src/validate_pin_test.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock implements HttpsCallableResult<dynamic> {}

void main() {
  late _MockFunctions functions;
  late _MockCallable callable;
  late FirebaseDatabaseRepository repository;

  setUp(() {
    functions = _MockFunctions();
    callable = _MockCallable();
    when(() => functions.httpsCallable('validatePin')).thenReturn(callable);
    repository = FirebaseDatabaseRepository(
      firebase: FakeFirebaseFirestore(),
      functions: functions,
    );
  });

  void stubResult(Map<String, dynamic> data) {
    final result = _MockResult();
    when(() => result.data).thenReturn(data);
    when(() => callable.call<dynamic>(any())).thenAnswer((_) async => result);
  }

  test('valid response maps to PinValid', () async {
    stubResult({'valid': true});
    final result = await repository.validatePin(
      targetUserId: 'friend1',
      pin: '0742',
    );
    expect(result, const PinValid());
    verify(
      () => callable.call<dynamic>({'targetUserId': 'friend1', 'pin': '0742'}),
    ).called(1);
  });

  test('invalid response maps to PinInvalid with attemptsRemaining', () async {
    stubResult({'valid': false, 'attemptsRemaining': 3});
    final result = await repository.validatePin(
      targetUserId: 'friend1',
      pin: '9999',
    );
    expect(result, const PinInvalid(attemptsRemaining: 3));
  });

  test('resource-exhausted maps to PinLockedOut with lockedUntil', () async {
    final until = DateTime.now().add(const Duration(minutes: 15));
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(
        code: 'resource-exhausted',
        message: 'locked',
        details: {'lockedUntilMillis': until.millisecondsSinceEpoch},
      ),
    );
    final result = await repository.validatePin(
      targetUserId: 'friend1',
      pin: '0742',
    );
    expect(result, isA<PinLockedOut>());
    expect(
      (result as PinLockedOut).lockedUntil.millisecondsSinceEpoch,
      until.millisecondsSinceEpoch,
    );
  });

  test('unavailable/internal errors map to PinCheckUnavailable', () async {
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(code: 'unavailable', message: 'offline'),
    );
    expect(
      await repository.validatePin(targetUserId: 'f', pin: '0742'),
      const PinCheckUnavailable(),
    );
  });

  test('permission-denied and failed-precondition surface as unavailable',
      () async {
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(code: 'failed-precondition', message: 'no pin'),
    );
    expect(
      await repository.validatePin(targetUserId: 'f', pin: '0742'),
      const PinCheckUnavailable(),
    );
  });
}
```

- [ ] **Step 3: Run to verify failure**

Run: `cd packages/firebase_database_repository && flutter test test/src/validate_pin_test.dart`
Expected: FAIL — constructor has no `functions` parameter; `validatePin` has the old positional signature.

- [ ] **Step 4: Implement.** In `firebase_database_repository.dart`:

Add import: `import 'package:cloud_functions/cloud_functions.dart';`

Change the constructor (drops `const` — a lazily-resolved field is added):

```dart
  FirebaseDatabaseRepository({
    required FirebaseFirestore firebase,
    FirebaseFunctions? functions,
  })  : _firebase = firebase,
        _functionsOverride = functions;

  final FirebaseFirestore _firebase;
  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;
```

Replace the old `validatePin` entirely:

```dart
  /// Validates a friend's PIN via the `validatePin` Cloud Function.
  ///
  /// The hash never reaches this client; the server enforces the
  /// 5-failures / 15-minute lockout and the friends-only precondition.
  Future<PinValidationResult> validatePin({
    required String targetUserId,
    required String pin,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('validatePin')
          .call<dynamic>({'targetUserId': targetUserId, 'pin': pin});
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['valid'] == true) return const PinValid();
      return PinInvalid(
        attemptsRemaining: (data['attemptsRemaining'] as num?)?.toInt() ?? 0,
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        final details = e.details;
        final millis = details is Map
            ? (details['lockedUntilMillis'] as num?)?.toInt()
            : null;
        return PinLockedOut(
          lockedUntil: millis != null
              ? DateTime.fromMillisecondsSinceEpoch(millis)
              : DateTime.now().add(const Duration(minutes: 15)),
        );
      }
      return const PinCheckUnavailable();
    } catch (_) {
      return const PinCheckUnavailable();
    }
  }
```

Update the three `main_*.dart` files. Each currently constructs `FirebaseDatabaseRepository(firebase: ...)` at line ~21 — add the functions argument so the flavor entrypoints are explicit:

```dart
      final firebaseDatabaseRepository = FirebaseDatabaseRepository(
        firebase: FirebaseFirestore.instance,
        functions: FirebaseFunctions.instance,
      );
```

with import `package:cloud_functions/cloud_functions.dart` added to each file. (Match the existing argument — read the file first; if it passes a different Firestore expression, keep it and only add `functions:`.)

- [ ] **Step 5: Run all package tests + analyze**

Run: `cd packages/firebase_database_repository && flutter test && cd ../.. && flutter analyze lib/main_development.dart lib/main_staging.dart lib/main_production.dart`
Expected: package tests PASS; analyze reports no NEW errors in the three entrypoints. `flutter analyze` at the repo root will now flag the old `validatePin(userId, pin)` call in `player_customization_bloc.dart` — that is expected and fixed in Task 8; do not fix it here.

- [ ] **Step 6: Commit**

```bash
git add packages/firebase_database_repository pubspec.yaml pubspec.lock lib/main_development.dart lib/main_staging.dart lib/main_production.dart
git commit -m "feat: validatePin repository call routes through the Cloud Function"
```

---

### Task 8: PlayerCustomizationBloc + PIN dialog — typed error states with lockout and offline

**Files:**
- Modify: `lib/player/view/bloc/player_customization_state.dart`
- Modify: `lib/player/view/bloc/player_customization_bloc.dart:216-236` (`_onValidatePin`)
- Modify: `lib/player/view/customize_player_page.dart:295-424` (`_showPinDialog`)
- Modify: `lib/l10n/arb/app_en.arb`, `lib/l10n/arb/app_es.arb`
- Test: `test/player/view/bloc/player_customization_bloc_test.dart` (add group; file may already exist — extend it, or create if missing)

**Interfaces:**
- Consumes: Task 7's `validatePin({targetUserId, pin}) → PinValidationResult`.
- Produces:
  - `enum PinFlowError { none, incorrect, lockedOut, unavailable }` declared in `player_customization_state.dart`
  - State fields: `PinFlowError pinFlowError` (default `.none`), `int pinAttemptsRemaining` (default `0`), `DateTime? pinLockedUntil` — **replacing** `String pinError`. `pinValidated` stays.
  - `copyWith` gains the three fields; `pinLockedUntil` uses a nullable-preserving setter: `DateTime? Function()? pinLockedUntil`.

- [ ] **Step 1: Write failing bloc tests.** In the player customization bloc test file, add (adjusting the bloc constructor arguments to match the existing test file's setup — reuse its mocks):

```dart
    group('ValidatePin', () {
      blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
        'emits pinValidated on PinValid',
        build: () {
          when(
            () => firebaseDatabaseRepository.validatePin(
              targetUserId: 'friend1',
              pin: '0742',
            ),
          ).thenAnswer((_) async => const PinValid());
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const ValidatePin(pin: '0742', friendUserId: 'friend1')),
        expect: () => [
          isA<PlayerCustomizationState>()
              .having((s) => s.pinValidated, 'pinValidated', true)
              .having((s) => s.pinFlowError, 'pinFlowError', PinFlowError.none),
        ],
      );

      blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
        'emits incorrect with attemptsRemaining on PinInvalid',
        build: () {
          when(
            () => firebaseDatabaseRepository.validatePin(
              targetUserId: 'friend1',
              pin: '9999',
            ),
          ).thenAnswer((_) async => const PinInvalid(attemptsRemaining: 2));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const ValidatePin(pin: '9999', friendUserId: 'friend1')),
        expect: () => [
          isA<PlayerCustomizationState>()
              .having((s) => s.pinValidated, 'pinValidated', false)
              .having(
                (s) => s.pinFlowError,
                'pinFlowError',
                PinFlowError.incorrect,
              )
              .having((s) => s.pinAttemptsRemaining, 'attempts', 2),
        ],
      );

      blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
        'emits lockedOut with expiry on PinLockedOut',
        build: () {
          when(
            () => firebaseDatabaseRepository.validatePin(
              targetUserId: 'friend1',
              pin: '9999',
            ),
          ).thenAnswer(
            (_) async => PinLockedOut(lockedUntil: DateTime(2026, 7, 3, 12)),
          );
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const ValidatePin(pin: '9999', friendUserId: 'friend1')),
        expect: () => [
          isA<PlayerCustomizationState>()
              .having(
                (s) => s.pinFlowError,
                'pinFlowError',
                PinFlowError.lockedOut,
              )
              .having(
                (s) => s.pinLockedUntil,
                'lockedUntil',
                DateTime(2026, 7, 3, 12),
              ),
        ],
      );

      blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
        'emits unavailable on PinCheckUnavailable',
        build: () {
          when(
            () => firebaseDatabaseRepository.validatePin(
              targetUserId: 'friend1',
              pin: '0742',
            ),
          ).thenAnswer((_) async => const PinCheckUnavailable());
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const ValidatePin(pin: '0742', friendUserId: 'friend1')),
        expect: () => [
          isA<PlayerCustomizationState>().having(
            (s) => s.pinFlowError,
            'pinFlowError',
            PinFlowError.unavailable,
          ),
        ],
      );
    });
```

If the test file does not exist, create it with the standard shape: mocktail mocks for every constructor dependency of `PlayerCustomizationBloc` (open `player_customization_bloc.dart:1-40` to read the constructor), a `buildBloc()` helper, and `registerFallbackValue` calls as needed.

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/player/view/bloc/player_customization_bloc_test.dart`
Expected: FAIL — `PinFlowError` undefined; repository stub signature mismatch.

- [ ] **Step 3: Implement state changes** in `player_customization_state.dart`: add at top level:

```dart
/// Errors surfaced by the friend-PIN validation flow.
enum PinFlowError {
  /// No error.
  none,

  /// The PIN was wrong.
  incorrect,

  /// Too many failed attempts; locked until [PlayerCustomizationState.pinLockedUntil].
  lockedOut,

  /// The check could not run (offline or server error).
  unavailable,
}
```

Replace `this.pinError = ''` / `final String pinError` with:

```dart
    this.pinFlowError = PinFlowError.none,
    this.pinAttemptsRemaining = 0,
    this.pinLockedUntil,
```

```dart
  final PinFlowError pinFlowError;
  final int pinAttemptsRemaining;
  final DateTime? pinLockedUntil;
```

Update `props` (replace `pinError` with the three new fields) and `copyWith` (replace the `pinError` parameter with `PinFlowError? pinFlowError`, `int? pinAttemptsRemaining`, `DateTime? Function()? pinLockedUntil`; apply `pinLockedUntil: pinLockedUntil != null ? pinLockedUntil() : this.pinLockedUntil`).

- [ ] **Step 4: Implement bloc changes.** Replace `_onValidatePin` (currently lines 216-236) with:

```dart
  Future<void> _onValidatePin(
    ValidatePin event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    final result = await _firebaseDatabaseRepository.validatePin(
      targetUserId: event.friendUserId,
      pin: event.pin,
    );
    switch (result) {
      case PinValid():
        emit(
          state.copyWith(
            pinValidated: true,
            pinFlowError: PinFlowError.none,
            pinLockedUntil: () => null,
          ),
        );
      case PinInvalid(:final attemptsRemaining):
        emit(
          state.copyWith(
            pinValidated: false,
            pinFlowError: PinFlowError.incorrect,
            pinAttemptsRemaining: attemptsRemaining,
            pinLockedUntil: () => null,
          ),
        );
      case PinLockedOut(:final lockedUntil):
        emit(
          state.copyWith(
            pinValidated: false,
            pinFlowError: PinFlowError.lockedOut,
            pinLockedUntil: () => lockedUntil,
          ),
        );
      case PinCheckUnavailable():
        emit(
          state.copyWith(
            pinValidated: false,
            pinFlowError: PinFlowError.unavailable,
            pinLockedUntil: () => null,
          ),
        );
    }
  }
```

Also update the `SelectFriend` handler at line 206: `pinError: ''` becomes `pinFlowError: PinFlowError.none`. Run `grep -n "pinError" lib/` and update every remaining reference the same way.

- [ ] **Step 5: Add l10n strings.** In `lib/l10n/arb/app_en.arb`:

```json
  "pinIncorrectError": "Incorrect PIN. {count, plural, =1{1 attempt} other{{count} attempts}} remaining.",
  "@pinIncorrectError": {
    "placeholders": { "count": { "type": "int" } }
  },
  "pinLockedOutError": "Too many attempts. Try again in {minutes} min.",
  "@pinLockedOutError": {
    "placeholders": { "minutes": { "type": "int" } }
  },
  "pinUnavailableError": "Couldn't verify the PIN. Check your connection and try again.",
```

In `lib/l10n/arb/app_es.arb`:

```json
  "pinIncorrectError": "PIN incorrecto. {count, plural, =1{Queda 1 intento} other{Quedan {count} intentos}}.",
  "pinLockedOutError": "Demasiados intentos. Inténtalo de nuevo en {minutes} min.",
  "pinUnavailableError": "No se pudo verificar el PIN. Revisa tu conexión e inténtalo de nuevo.",
```

Run: `flutter gen-l10n --arb-dir="lib/l10n/arb"`

- [ ] **Step 6: Update the dialog** in `customize_player_page.dart`. In `_showPinDialog`:
  - `listenWhen` (lines 308-310): replace `previous.pinError != current.pinError` with `previous.pinFlowError != current.pinFlowError`.
  - `buildWhen` (lines 339-340): replace `previous.pinError != current.pinError` with `previous.pinFlowError != current.pinFlowError || previous.pinAttemptsRemaining != current.pinAttemptsRemaining || previous.pinLockedUntil != current.pinLockedUntil`.
  - `errorText` (lines 380-382): replace with a mapping helper placed above `_showPinDialog`:

```dart
  String? _pinErrorText(BuildContext context, PlayerCustomizationState state) {
    final l10n = context.l10n;
    return switch (state.pinFlowError) {
      PinFlowError.none => null,
      PinFlowError.incorrect =>
        l10n.pinIncorrectError(state.pinAttemptsRemaining),
      PinFlowError.lockedOut => l10n.pinLockedOutError(
          state.pinLockedUntil == null
              ? 15
              : state.pinLockedUntil!
                  .difference(DateTime.now())
                  .inMinutes
                  .clamp(1, 15),
        ),
      PinFlowError.unavailable => l10n.pinUnavailableError,
    };
  }
```

  used as `errorText: _pinErrorText(context, state)`.
  - Disable the Verify button during lockout: wrap the `FilledButton` (lines 402-414) in a `BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>` (buildWhen on `pinFlowError`) and set `onPressed` to `null` when `state.pinFlowError == PinFlowError.lockedOut`, otherwise keep the existing 4-digit gate.

- [ ] **Step 7: Run tests + analyze**

Run: `flutter test test/player && flutter analyze`
Expected: bloc tests PASS; analyze clean except pre-existing `app_ui`/gallery issues.

- [ ] **Step 8: Commit**

```bash
git add lib/player lib/l10n test/player
git commit -m "feat: typed PIN error states with lockout and offline handling in player customization"
```

---

### Task 9: Onboarding — `hasExistingPin` flag + PIN writes go to private credentials

**Files:**
- Modify: `lib/onboarding/bloc/onboarding_bloc.dart`
- Modify: `lib/onboarding/bloc/onboarding_state.dart`
- Modify: `lib/onboarding/view/onboarding_form.dart:261-268` (`_PinStep`)
- Test: `test/onboarding/bloc/onboarding_bloc_test.dart` (extend or create following existing test conventions)

**Interfaces:**
- Consumes: Task 6's `setPin`, Task 5's `hasPin` model field.
- Produces: `OnboardingState.hasExistingPin` (`bool`, replaces `String? existingPinHash`); submitted profiles carry `hasPin: true` and never a `pin` value.

- [ ] **Step 1: Write failing bloc tests** (extend the onboarding bloc test file, reusing its existing mocks and helpers):

```dart
    group('PIN handling', () {
      test('empty legacy pin string does NOT count as an existing PIN', () {
        final bloc = OnboardingBloc(
          firebaseDatabaseRepository: firebaseDatabaseRepository,
          existingProfile: const UserProfileModel(id: 'u1', pin: ''),
        );
        expect(bloc.state.hasExistingPin, isFalse);
        addTearDown(bloc.close);
      });

      test('hasPin flag counts as an existing PIN', () {
        final bloc = OnboardingBloc(
          firebaseDatabaseRepository: firebaseDatabaseRepository,
          existingProfile: const UserProfileModel(id: 'u1', hasPin: true),
        );
        expect(bloc.state.hasExistingPin, isTrue);
        addTearDown(bloc.close);
      });

      blocTest<OnboardingBloc, OnboardingState>(
        'submit with a new PIN calls setPin and writes hasPin without pin',
        build: () {
          when(() => firebaseDatabaseRepository.getUserProfileOnce('u1'))
              .thenAnswer((_) async => null);
          when(() => firebaseDatabaseRepository.generateUniqueFriendCode())
              .thenAnswer((_) async => 'YETI-A3F9');
          when(() => firebaseDatabaseRepository.setPin('u1', '0742'))
              .thenAnswer((_) async {});
          when(
            () => firebaseDatabaseRepository.updateUserProfile(
              'u1',
              any(),
            ),
          ).thenAnswer((_) async {});
          return buildBloc();
        },
        seed: () => OnboardingState(
          username: const Username.dirty('josh'),
          pin: const Pin.dirty('0742'),
        ),
        act: (bloc) => bloc.add(const OnboardingSubmitted('u1')),
        verify: (_) {
          verify(() => firebaseDatabaseRepository.setPin('u1', '0742'))
              .called(1);
          final profile = verify(
            () => firebaseDatabaseRepository.updateUserProfile(
              'u1',
              captureAny(),
            ),
          ).captured.single as UserProfileModel;
          expect(profile.hasPin, isTrue);
          expect(profile.pin, isNull);
          expect(profile.onboardingComplete, isTrue);
        },
      );
    });
```

(Adjust `updateUserProfile` verification to the real method name/signature in the bloc — read `onboarding_bloc.dart:106-153` first; if the submit handler passes the model positionally or the method has a different name, mirror it exactly in the test.)

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/onboarding`
Expected: FAIL — `hasExistingPin` undefined.

- [ ] **Step 3: Implement.**

`onboarding_state.dart`: replace `final String? existingPinHash` with `final bool hasExistingPin` (default `false`); update constructor, `copyWith`, `props`, and `isStepValid` case 1 to:

```dart
      case 1:
        return pin.isValid || hasExistingPin;
```

`onboarding_bloc.dart` constructor (lines 15-26): replace `existingPinHash: existingProfile?.pin` with:

```dart
            hasExistingPin: (existingProfile?.hasPin ?? false) ||
                (existingProfile?.pin?.isNotEmpty ?? false),
```

`_onSubmitted` (lines 106-153): remove the `pinHash` computation and the `pin:` argument from the saved `UserProfileModel`; instead pass `hasPin: state.pin.value.isNotEmpty || state.hasExistingPin` and, when `state.pin.value.isNotEmpty`, call `await _firebaseDatabaseRepository.setPin(event.userId, state.pin.value);` immediately after the profile save.

`onboarding_form.dart` `_PinStep` (lines 256-311): replace both `state.existingPinHash != current.existingPinHash` in `buildWhen` and `final hasExistingPin = state.existingPinHash != null` with the `hasExistingPin` bool field (`previous.hasExistingPin != current.hasExistingPin`, `final hasExistingPin = state.hasExistingPin`).

- [ ] **Step 4: Run tests + analyze**

Run: `flutter test test/onboarding && flutter analyze`
Expected: PASS; no new analyzer issues.

- [ ] **Step 5: Commit**

```bash
git add lib/onboarding test/onboarding
git commit -m "feat: onboarding PIN writes to private credentials and closes empty-PIN loophole"
```

---

### Task 10: AppBloc — run lazy PIN migration during profile load

**Files:**
- Modify: `lib/app/bloc/app_bloc.dart:100-139` (`_onUserChanged`)
- Test: `test/app/bloc/app_bloc_test.dart` (extend)

**Interfaces:**
- Consumes: Task 6's `migrateLegacyPin`.
- Produces: guarantee relied on by Plan B — by the time a profile is evaluated for gating, the user's own legacy `pin` field has been migrated (or migration was attempted).

- [ ] **Step 1: Write the failing test** (extend the AppBloc test file with its existing mock setup):

```dart
      blocTest<AppBloc, AppState>(
        'migrates legacy PIN before evaluating the profile',
        setUp: () {
          when(() => firebaseDatabaseRepository.migrateLegacyPin('user1'))
              .thenAnswer((_) async {});
          when(() => firebaseDatabaseRepository.getUserProfileOnce('user1'))
              .thenAnswer(
            (_) async => const UserProfileModel(
              id: 'user1',
              username: 'josh',
              hasPin: true,
              onboardingComplete: true,
            ),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(AppUserChanged(authenticatedUser)),
        verify: (_) {
          verifyInOrder([
            () => firebaseDatabaseRepository.migrateLegacyPin('user1'),
            () => firebaseDatabaseRepository.getUserProfileOnce('user1'),
          ]);
        },
      );
```

(Match the existing test file's user fixtures: `authenticatedUser` should be whatever non-anonymous `User` fixture the file already uses, with id `user1` — adjust ids to the fixture's actual value.)

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/app`
Expected: FAIL — `migrateLegacyPin` never called.

- [ ] **Step 3: Implement.** In `_onUserChanged`, immediately before the `getUserProfileOnce` call (line ~126), add:

```dart
      // Lazily move any legacy profile-doc PIN hash into the private
      // credentials doc before the profile is evaluated. Best-effort:
      // the callable's legacy fallback covers failures.
      await _firebaseDatabaseRepository.migrateLegacyPin(event.user.id);
```

(Inside the existing try block, before the profile fetch, so the generation-counter race guard still applies to the fetch result.)

- [ ] **Step 4: Run tests**

Run: `flutter test test/app`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app test/app
git commit -m "feat: migrate legacy PIN hashes to private credentials on login"
```

---

### Task 11: Full verification + deployment staging

**Files:**
- Create: `docs/superpowers/plans/2026-07-03-friends-INDEX.md` (plan tracker)
- Modify: `README.md` (add a "Firebase backend" section if one doesn't exist)

**Interfaces:**
- Consumes: everything above.
- Produces: a verified, deployable Plan A; the INDEX file that Plans B–D update.

- [ ] **Step 1: Run the full verification suite**

```bash
flutter analyze
flutter test
cd packages/firebase_database_repository && flutter test && cd ../..
cd functions && npm run build && npm test && cd ..
firebase emulators:exec --only firestore "npm --prefix functions run test:rules"
```

Expected: all PASS; analyze clean except pre-existing `app_ui`/gallery issues. Fix anything new before proceeding.

- [ ] **Step 2: Add README section** describing the backend layout (`functions/`, `firestore.rules`), the emulator commands above, and the deploy command:

```bash
firebase deploy --only firestore:rules,functions
```

- [ ] **Step 3: Create the plan INDEX** at `docs/superpowers/plans/2026-07-03-friends-INDEX.md`:

```markdown
# Friends Feature — Plan Index

Spec: docs/superpowers/specs/2026-07-03-friends-feature-design.md
Branch: feat/friends-hardening

| Plan | Scope (spec phases) | Status |
|---|---|---|
| A `2026-07-03-friends-a-backend-foundation.md` | Functions + rules + private PIN (1) | in progress |
| B (not yet written) | Legacy gate + game fan-out (2–3) | pending |
| C (not yet written) | Social graph rules + blocking (4–5) | pending |
| D (not yet written) | Profile page + cleanup (6–7) | pending |

**DEPLOY GATE:** before the first `firebase deploy --only firestore:rules`, export
the project's CURRENT production rules from the Firebase console and diff them
against `firestore.rules` — the console rules were never versioned and may contain
grants this repo doesn't know about. Deployment is run by Josh, not by an agent.
```

Update the Plan A row to `complete` once Step 1 passes.

- [ ] **Step 4: Commit**

```bash
git add README.md docs/superpowers/plans/2026-07-03-friends-INDEX.md docs/superpowers/plans/2026-07-03-friends-a-backend-foundation.md
git commit -m "chore: verify friends backend foundation; add plan index and deploy gate"
```
