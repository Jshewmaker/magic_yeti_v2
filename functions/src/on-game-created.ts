import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

// A `/` in an id would address a different document path entirely (path
// traversal into an arbitrary collection/doc) and, under `retry: true`, a
// thrown batch would starve legitimate recipients for the whole retry
// window. Reject anything that isn't a plausible bare uid before it's used
// to build a document path.
function isPlausibleUid(value: unknown): value is string {
  return typeof value === 'string' && value.length > 0 && !value.includes('/');
}

/**
 * Fans a newly saved game out to every linked player's match history.
 * Recipients: set(hostId ∪ players[].firebaseId). Idempotent — the copy
 * doc id is the games/ doc id, so retries and re-fires overwrite in place.
 */
export const onGameCreated = onDocumentCreated(
  { document: 'games/{gameId}', retry: true },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const game = snapshot.data();
    const gameId = event.params.gameId;

    const ids = new Set<string>();
    if (isPlausibleUid(game.hostId)) {
      ids.add(game.hostId);
    }
    const players = Array.isArray(game.players) ? game.players : [];
    for (const player of players) {
      const firebaseId = player?.firebaseId;
      if (isPlausibleUid(firebaseId)) {
        ids.add(firebaseId);
      }
    }
    if (ids.size === 0) return;

    const db = admin.firestore();
    const batch = db.batch();
    for (const id of ids) {
      batch.set(db.doc(`users/${id}/matches/${gameId}`), game);
    }
    await batch.commit();
  },
);
