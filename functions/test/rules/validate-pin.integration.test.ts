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

test('targetUserId containing a slash is rejected', async () => {
  await expect(
    wrapped({ data: { targetUserId: 'a/b', pin: '0742' }, auth: callerAuth }),
  ).rejects.toMatchObject({ code: 'invalid-argument' });
});
