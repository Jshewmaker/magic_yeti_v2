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
