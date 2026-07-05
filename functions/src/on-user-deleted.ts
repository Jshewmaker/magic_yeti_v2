import * as admin from 'firebase-admin';
// firebase-functions v2 has no user-deletion trigger — auth.user().onDelete
// only exists in v1, so this module coexists with the v2 exports elsewhere.
import * as functionsV1 from 'firebase-functions/v1';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const BATCH_LIMIT = 400;

/**
 * Deletes every doc in `query`, chunked at BATCH_LIMIT per commit so
 * fan-out that grows past a single batch's 500-write cap doesn't throw.
 */
async function deleteQueryResults(query: FirebaseFirestore.Query): Promise<void> {
  const snapshot = await query.get();
  if (snapshot.empty) return;

  const db = admin.firestore();
  for (let i = 0; i < snapshot.docs.length; i += BATCH_LIMIT) {
    const chunk = snapshot.docs.slice(i, i + BATCH_LIMIT);
    const batch = db.batch();
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
}

/**
 * Cleans up the social graph when an auth account is deleted. Each step is
 * independently idempotent, so retries or partial failures are safe:
 *
 * 1. users/{uid} subtree — profile, private, own blocks, own matches.
 * 2. friends/{uid} subtree — the victim's own friend list.
 * 3. Other users' friendList edges pointing at the victim.
 * 4. friendRequests naming the victim as sender or receiver, any status —
 *    a declined doc is just a suppression marker, moot once the account
 *    is gone.
 * 5. Other users' blocks docs naming the victim, freeing the doc-id slot
 *    if they re-register.
 *
 * Games and other users' match history are untouched — shared game
 * history survives the account that created it.
 */
export const onUserDeleted = functionsV1.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const db = admin.firestore();

  await db.recursiveDelete(db.doc(`users/${uid}`));
  await db.recursiveDelete(db.doc(`friends/${uid}`));

  await deleteQueryResults(
    db.collectionGroup('friendList').where('userId', '==', uid),
  );

  await deleteQueryResults(
    db.collection('friendRequests').where('senderId', '==', uid),
  );
  await deleteQueryResults(
    db.collection('friendRequests').where('receiverId', '==', uid),
  );

  await deleteQueryResults(
    db.collectionGroup('blocks').where('userId', '==', uid),
  );
});
