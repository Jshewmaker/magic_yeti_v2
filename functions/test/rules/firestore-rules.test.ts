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
});

describe('games', () => {
  test('signed-in user can create a game they host; foreign hostId denied', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'games/g10'), { hostId: 'alice', roomId: 'AB2C' }),
    );
    await assertFails(
      setDoc(doc(alice(), 'games/g11'), { hostId: 'bob', roomId: 'CD3E' }),
    );
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
