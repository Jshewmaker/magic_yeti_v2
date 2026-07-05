import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import {
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  collection,
  where,
  limit,
} from 'firebase/firestore';

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
    // Any signed-in user may read a game (game-code lookup).
    await assertSucceeds(getDoc(doc(bob(), 'games/g10')));
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
});

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

  test('declined docs cannot be deleted (delete-and-recreate suppression dodge)', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friendRequests/alice_bob'), {
        ...pending,
        status: 'declined',
      });
    });
    await assertFails(deleteDoc(doc(alice(), 'friendRequests/alice_bob')));
    await assertFails(deleteDoc(doc(bob(), 'friendRequests/alice_bob')));
  });

  test('point get on a NONEXISTENT request doc is denied (why the client uses queries)', async () => {
    await assertFails(getDoc(doc(alice(), 'friendRequests/alice_bob')));
  });

  test('participant-constrained queries are allowed with no matching docs', async () => {
    await assertSucceeds(
      getDocs(query(
        collection(alice(), 'friendRequests'),
        where('senderId', '==', 'alice'),
        where('receiverId', '==', 'bob'),
        limit(1),
      )),
    );
    await assertSucceeds(
      getDocs(query(
        collection(alice(), 'friendRequests'),
        where('senderId', '==', 'bob'),
        where('receiverId', '==', 'alice'),
        where('status', '==', 'pending'),
        limit(1),
      )),
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

  test('edge doc userId must match its key even with a valid pending gate', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friendRequests/alice_bob'), {
        senderId: 'alice',
        receiverId: 'bob',
        status: 'pending',
      });
    });
    // FriendModel.userId feeds PIN-validation targets — a mismatched field
    // would point the friend tile at a different account.
    await assertFails(
      setDoc(doc(bob(), 'friends/bob/friendList/alice'), { userId: 'mallory' }),
    );
    await assertFails(
      setDoc(doc(bob(), 'friends/alice/friendList/bob'), { userId: 'mallory' }),
    );
  });

  test('owner may always delete own edges; you may always delete yourself from another list', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const seedDb = ctx.firestore();
      await setDoc(doc(seedDb, 'friends/alice/friendList/bob'), { userId: 'bob' });
      await setDoc(doc(seedDb, 'friends/bob/friendList/alice'), { userId: 'alice' });
    });
    const aliceDb = alice();
    await assertSucceeds(deleteDoc(doc(aliceDb, 'friends/alice/friendList/bob')));
    await assertSucceeds(deleteDoc(doc(aliceDb, 'friends/bob/friendList/alice')));
  });

  test("a third party cannot delete someone else's edge", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friends/alice/friendList/bob'), { userId: 'bob' });
    });
    await assertFails(
      deleteDoc(doc(env.authenticatedContext('carol').firestore(), 'friends/alice/friendList/bob')),
    );
  });

  test('a declined request grants no edge writes, even for the decliner', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'friendRequests/alice_bob'), {
        senderId: 'alice', receiverId: 'bob', status: 'declined',
      });
    });
    await assertFails(setDoc(doc(bob(), 'friends/bob/friendList/alice'), { userId: 'alice' }));
    await assertFails(setDoc(doc(bob(), 'friends/alice/friendList/bob'), { userId: 'bob' }));
  });

  test('a block denies edge writes even with a pending request', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const seedDb = ctx.firestore();
      await setDoc(doc(seedDb, 'friendRequests/alice_bob'), {
        senderId: 'alice', receiverId: 'bob', status: 'pending',
      });
      await setDoc(doc(seedDb, 'users/alice/blocks/bob'), { blockedAt: 1 });
    });
    await assertFails(setDoc(doc(bob(), 'friends/bob/friendList/alice'), { userId: 'alice' }));
    await assertFails(setDoc(doc(bob(), 'friends/alice/friendList/bob'), { userId: 'bob' }));
  });
});
