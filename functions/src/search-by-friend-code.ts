import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { isBlocked, resolveRelationship, toSearchPayload } from './search-helpers';

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
  if (await isBlocked(db, targetId, callerUid)) {
    return { found: false };
  }

  const relationship = await resolveRelationship(db, targetId, callerUid);

  return {
    found: true,
    user: toSearchPayload(targetId, target.data(), code),
    relationship,
  };
});
