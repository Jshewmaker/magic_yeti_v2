import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  AttemptState,
  checkPin,
  evaluateAttempt,
  MAX_ATTEMPTS,
  recordFailure,
  StoredCredentials,
} from './pin-logic';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface ValidatePinRequest {
  targetUserId?: string;
  pin?: string;
}

export const validatePin = onCall<ValidatePinRequest>(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  if (auth.token?.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Anonymous users cannot validate PINs.');
  }

  const { targetUserId, pin } = request.data ?? {};
  if (typeof targetUserId !== 'string' || targetUserId.length === 0) {
    throw new HttpsError('invalid-argument', 'targetUserId is required.');
  }
  if (targetUserId.includes('/')) {
    throw new HttpsError('invalid-argument', 'targetUserId is malformed.');
  }
  if (typeof pin !== 'string' || !/^\d{4}$/.test(pin)) {
    throw new HttpsError('invalid-argument', 'pin must be exactly 4 digits.');
  }

  const db = admin.firestore();
  const callerUid = auth.uid;

  // Only friends of the target may attempt validation.
  const friendEdge = await db
    .doc(`friends/${targetUserId}/friendList/${callerUid}`)
    .get();
  if (!friendEdge.exists) {
    throw new HttpsError('permission-denied', 'Caller is not a friend of the target.');
  }

  const credentialsRef = db.doc(`users/${targetUserId}/private/credentials`);
  const legacyProfileRef = db.doc(`users/${targetUserId}`);
  const attemptsRef = db.doc(`pinAttempts/${callerUid}_${targetUserId}`);

  return db.runTransaction(async (tx) => {
    // All transactional reads must happen before any writes.
    const credentials = await tx.get(credentialsRef);
    const legacyProfile = credentials.exists
      ? null
      : await tx.get(legacyProfileRef);
    const attemptsSnap = await tx.get(attemptsRef);

    const now = Date.now();

    // Load stored credentials: private doc first, legacy profile field fallback.
    let stored: StoredCredentials | null = null;
    if (credentials.exists) {
      const data = credentials.data()!;
      stored = {
        pinHash: data.pinHash as string,
        salt: (data.salt as string | null) ?? null,
      };
    } else {
      const legacyHash = legacyProfile?.data()?.pin as string | undefined;
      if (legacyHash != null && legacyHash.length > 0) {
        stored = { pinHash: legacyHash, salt: null };
      }
    }
    if (stored === null) {
      throw new HttpsError('failed-precondition', 'Target user has no PIN set.');
    }

    const state: AttemptState | null = attemptsSnap.exists
      ? {
          failCount: attemptsSnap.data()!.failCount as number,
          lockedUntilMillis:
            (attemptsSnap.data()!.lockedUntilMillis as number | null) ?? null,
        }
      : null;

    const lock = evaluateAttempt(state, now);
    if (lock.lockedOut) {
      throw new HttpsError('resource-exhausted', 'Too many failed attempts.', {
        lockedUntilMillis: lock.lockedUntilMillis,
      });
    }

    if (checkPin(stored, pin)) {
      if (attemptsSnap.exists) {
        tx.delete(attemptsRef);
      }
      return { valid: true };
    }

    const next = recordFailure(state, now);
    tx.set(attemptsRef, {
      failCount: next.failCount,
      lockedUntilMillis: next.lockedUntilMillis,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {
      valid: false,
      attemptsRemaining: Math.max(0, MAX_ATTEMPTS - next.failCount),
    };
  });
});
