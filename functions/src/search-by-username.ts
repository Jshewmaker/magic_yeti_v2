import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { isBlocked, resolveRelationship, toSearchPayload } from './search-helpers';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface SearchRequest {
  query?: string;
}

const MAX_RESULTS = 10;
const MIN_QUERY_LENGTH = 2;

export const searchByUsername = onCall<SearchRequest>(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  if (auth.token?.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Anonymous users cannot search.');
  }
  const raw = request.data?.query;
  if (typeof raw !== 'string' || raw.trim().length < MIN_QUERY_LENGTH) {
    throw new HttpsError(
      'invalid-argument',
      `query must be at least ${MIN_QUERY_LENGTH} characters.`,
    );
  }
  const prefix = raw.trim().toLowerCase();
  const callerUid = auth.uid;

  const db = admin.firestore();
  const snapshot = await db
    .collection('users')
    .where('usernameLower', '>=', prefix)
    .where('usernameLower', '<', `${prefix}`)
    .limit(MAX_RESULTS)
    .get();

  const candidates = await Promise.all(
    snapshot.docs.map(async (targetDoc) => {
      const targetId = targetDoc.id;
      if (await isBlocked(db, targetId, callerUid)) return null;
      const relationship = await resolveRelationship(db, targetId, callerUid);
      return { user: toSearchPayload(targetId, targetDoc.data()), relationship };
    }),
  );

  return {
    matches: candidates.filter((c): c is NonNullable<typeof c> => c !== null),
  };
});
