import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

if (admin.apps.length === 0) {
  admin.initializeApp();
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
    if (typeof game.hostId === 'string' && game.hostId.length > 0) {
      ids.add(game.hostId);
    }
    const players = Array.isArray(game.players) ? game.players : [];
    for (const player of players) {
      const firebaseId = player?.firebaseId;
      if (typeof firebaseId === 'string' && firebaseId.length > 0) {
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
