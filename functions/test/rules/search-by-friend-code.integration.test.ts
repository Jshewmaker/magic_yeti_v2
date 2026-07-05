/**
 * Runs inside `firebase emulators:exec --only firestore` via the test:rules
 * script. Uses firebase-functions-test in online mode against the emulator.
 */
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.GCLOUD_PROJECT = 'magic-yeti-fn-test';

import functionsTest from 'firebase-functions-test';
import * as admin from 'firebase-admin';

const testEnv = functionsTest({ projectId: 'magic-yeti-fn-test' });
// Import AFTER functionsTest() so admin.initializeApp inside the module
// picks up emulator env.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { searchByFriendCode } = require('../../src/search-by-friend-code');

const db = admin.firestore();
const wrapped = testEnv.wrap(searchByFriendCode);

const caller = { uid: 'caller', token: { firebase: { sign_in_provider: 'password' } } };

async function seedTarget() {
  await db.doc('users/target').set({
    id: 'target',
    username: 'Target',
    imageUrl: 'http://x/y.png',
    friendCode: 'YETI-A3F9',
  });
}

afterAll(() => {
  // testEnv.cleanup() is synchronous (returns void in this version of
  // firebase-functions-test) — nothing to await here.
  testEnv.cleanup();
});

beforeEach(async () => {
  const collections = await db.listCollections();
  await Promise.all(
    collections.map((c) => db.recursiveDelete(c)),
  );
});

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
