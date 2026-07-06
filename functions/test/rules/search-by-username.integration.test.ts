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
const { searchByUsername } = require('../../src/search-by-username');

const db = admin.firestore();
const wrapped = testEnv.wrap(searchByUsername);

const caller = { uid: 'caller', token: { firebase: { sign_in_provider: 'password' } } };

async function seedUser(
  id: string,
  username: string,
  overrides: Record<string, unknown> = {},
) {
  await db.doc(`users/${id}`).set({
    id,
    username,
    usernameLower: username.toLowerCase(),
    imageUrl: 'http://x/y.png',
    friendCode: `YETI-${id.toUpperCase()}`,
    ...overrides,
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

test('finds users by lowercase prefix, case-insensitively', async () => {
  await seedUser('josh', 'Josh');
  await seedUser('john', 'John');
  await seedUser('mira', 'Mira');
  const r = await wrapped({ data: { query: 'Jo' }, auth: caller });
  const ids = r.matches.map((m: { user: { id: string } }) => m.user.id).sort();
  expect(ids).toEqual(['john', 'josh']);
});

test('no matches returns an empty list, not an error', async () => {
  await seedUser('josh', 'Josh');
  const r = await wrapped({ data: { query: 'zz' }, auth: caller });
  expect(r).toEqual({ matches: [] });
});

test('reports relationship per match and includes self', async () => {
  await seedUser('josh', 'Josh');
  await seedUser('caller', 'Caller');
  await db.doc('friends/josh/friendList/caller').set({ userId: 'caller' });
  const r = await wrapped({ data: { query: 'jo' }, auth: caller });
  expect(r.matches).toEqual([
    {
      user: { id: 'josh', username: 'Josh', imageUrl: 'http://x/y.png', friendCode: 'YETI-JOSH' },
      relationship: 'friends',
    },
  ]);

  const self = await wrapped({ data: { query: 'call' }, auth: caller });
  expect(self.matches[0].relationship).toBe('self');
});

test('block-hides either direction from the results', async () => {
  await seedUser('josh', 'Josh');
  await db.doc('users/josh/blocks/caller').set({ blockedAt: 1 });
  expect(await wrapped({ data: { query: 'jo' }, auth: caller })).toEqual({ matches: [] });

  await db.recursiveDelete(db.doc('users/josh').collection('blocks'));
  await db.doc('users/caller/blocks/josh').set({ blockedAt: 1 });
  expect(await wrapped({ data: { query: 'jo' }, auth: caller })).toEqual({ matches: [] });
});

test('anonymous/unauthenticated callers rejected; short query invalid', async () => {
  await expect(wrapped({ data: { query: 'jo' } })).rejects.toMatchObject({ code: 'unauthenticated' });
  await expect(
    wrapped({ data: { query: 'jo' }, auth: { uid: 'x', token: { firebase: { sign_in_provider: 'anonymous' } } } }),
  ).rejects.toMatchObject({ code: 'permission-denied' });
  await expect(wrapped({ data: { query: 'j' }, auth: caller })).rejects.toMatchObject({ code: 'invalid-argument' });
  await expect(wrapped({ data: { query: '' }, auth: caller })).rejects.toMatchObject({ code: 'invalid-argument' });
});
