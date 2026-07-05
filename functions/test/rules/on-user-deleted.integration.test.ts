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
const { onUserDeleted } = require('../../src/on-user-deleted');

const db = admin.firestore();
const wrapped = testEnv.wrap(onUserDeleted);

afterAll(() => {
  // testEnv.cleanup() is synchronous (returns void in this version of
  // firebase-functions-test) — nothing to await here.
  testEnv.cleanup();
});

beforeEach(async () => {
  const collections = await db.listCollections();
  await Promise.all(collections.map((c) => db.recursiveDelete(c)));
});

async function seed() {
  // Victim's own tree: profile, private/credentials, blocks/other, matches/g1.
  await db.doc('users/victim').set({ id: 'victim', username: 'Victim' });
  await db.doc('users/victim/private/credentials').set({ secret: 'shh' });
  await db.doc('users/victim/blocks/other').set({ userId: 'other', username: 'Other', imageUrl: '' });
  await db.doc('users/victim/matches/g1').set({ id: 'g1', roomId: 'AB2C' });

  // Victim's own friend list (friends/victim root) and the mirrored edge.
  await db.doc('friends/victim/friendList/friend1').set({ userId: 'friend1' });
  await db.doc('friends/friend1/friendList/victim').set({ userId: 'victim' });

  // Requests in both directions, different statuses.
  await db.doc('friendRequests/victim_friend1').set({
    senderId: 'victim',
    receiverId: 'friend1',
    status: 'pending',
  });
  await db.doc('friendRequests/friend2_victim').set({
    senderId: 'friend2',
    receiverId: 'victim',
    status: 'declined',
  });

  // friend1's block record naming the victim.
  await db.doc('users/friend1/blocks/victim').set({
    userId: 'victim',
    username: 'Victim',
    imageUrl: '',
  });

  // Shared game history that must survive cleanup untouched.
  await db.doc('games/g1').set({ id: 'g1', hostId: 'friend1', roomId: 'AB2C' });
  await db.doc('users/friend1/matches/g1').set({ id: 'g1', roomId: 'AB2C' });
}

test('deletes the victim social graph but leaves shared game history intact', async () => {
  await seed();

  await wrapped({ uid: 'victim' });

  // Victim's whole tree is gone.
  expect((await db.doc('users/victim').get()).exists).toBe(false);
  expect((await db.doc('users/victim/private/credentials').get()).exists).toBe(false);
  expect((await db.doc('users/victim/blocks/other').get()).exists).toBe(false);
  expect((await db.doc('users/victim/matches/g1').get()).exists).toBe(false);

  // Victim's own friend list root is gone.
  expect((await db.doc('friends/victim/friendList/friend1').get()).exists).toBe(false);
  const victimFriendListDocs = await db.collection('friends/victim/friendList').get();
  expect(victimFriendListDocs.size).toBe(0);

  // friend1's edge pointing at the victim is gone.
  expect((await db.doc('friends/friend1/friendList/victim').get()).exists).toBe(false);

  // Both friend requests involving the victim are gone, regardless of status.
  expect((await db.doc('friendRequests/victim_friend1').get()).exists).toBe(false);
  expect((await db.doc('friendRequests/friend2_victim').get()).exists).toBe(false);

  // friend1's block-of-victim doc is gone.
  expect((await db.doc('users/friend1/blocks/victim').get()).exists).toBe(false);

  // Shared game history is untouched.
  expect((await db.doc('games/g1').get()).exists).toBe(true);
  expect((await db.doc('users/friend1/matches/g1').get()).exists).toBe(true);
});
