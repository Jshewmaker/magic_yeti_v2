import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface SearchRequest {
  code?: string;
}

export const searchByFriendCode = onCall<SearchRequest>(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  if (auth.token?.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Anonymous users cannot search.');
  }
  const raw = request.data?.code;
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'code is required.');
  }
  const code = raw.trim().toUpperCase();

  const db = admin.firestore();
  const snapshot = await db
    .collection('users')
    .where('friendCode', '==', code)
    .limit(1)
    .get();
  if (snapshot.empty) return { found: false };

  const target = snapshot.docs[0];
  const targetId = target.id;
  const callerUid = auth.uid;

  // Block hiding: either direction reads as not-found.
  const [targetBlocksCaller, callerBlocksTarget] = await Promise.all([
    db.doc(`users/${targetId}/blocks/${callerUid}`).get(),
    db.doc(`users/${callerUid}/blocks/${targetId}`).get(),
  ]);
  if (targetBlocksCaller.exists || callerBlocksTarget.exists) {
    return { found: false };
  }

  let relationship = 'none';
  if (targetId === callerUid) {
    relationship = 'self';
  } else {
    const [edge, sent, received] = await Promise.all([
      // Deliberately the TARGET's list (is the caller on it), matching
      // validate-pin's gate. Edges can be asymmetric (users may remove
      // themselves from the other side); this direction fails CLOSED —
      // an inert "friends" display — where reading the caller's own list
      // would show "Add Friend" and create a spurious request against a
      // target who still lists the caller. Do not "fix" this back.
      db.doc(`friends/${targetId}/friendList/${callerUid}`).get(),
      db.doc(`friendRequests/${callerUid}_${targetId}`).get(),
      db.doc(`friendRequests/${targetId}_${callerUid}`).get(),
    ]);
    if (edge.exists) relationship = 'friends';
    else if (sent.exists && sent.data()?.status === 'pending') relationship = 'pendingSent';
    else if (received.exists && received.data()?.status === 'pending') relationship = 'pendingReceived';
  }

  const data = target.data();
  return {
    found: true,
    user: {
      id: targetId,
      username: (data.username as string | undefined) ?? '',
      imageUrl: (data.imageUrl as string | undefined) ?? '',
      friendCode: (data.friendCode as string | undefined) ?? code,
    },
    relationship,
  };
});
