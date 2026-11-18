import * as admin from 'firebase-admin';

export interface SearchUserPayload {
  id: string;
  username: string;
  imageUrl: string;
  friendCode: string;
}

/** Block hiding: true if either direction has blocked the other. */
export async function isBlocked(
  db: admin.firestore.Firestore,
  targetId: string,
  callerUid: string,
): Promise<boolean> {
  const [targetBlocksCaller, callerBlocksTarget] = await Promise.all([
    db.doc(`users/${targetId}/blocks/${callerUid}`).get(),
    db.doc(`users/${callerUid}/blocks/${targetId}`).get(),
  ]);
  return targetBlocksCaller.exists || callerBlocksTarget.exists;
}

/** Resolves the relationship string between caller and target. */
export async function resolveRelationship(
  db: admin.firestore.Firestore,
  targetId: string,
  callerUid: string,
): Promise<string> {
  if (targetId === callerUid) return 'self';

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
  if (edge.exists) return 'friends';
  if (sent.exists && sent.data()?.status === 'pending') return 'pendingSent';
  if (received.exists && received.data()?.status === 'pending') return 'pendingReceived';
  return 'none';
}

/** Shapes a users/{id} doc's public fields for a search response. */
export function toSearchPayload(
  id: string,
  data: FirebaseFirestore.DocumentData,
  fallbackFriendCode?: string,
): SearchUserPayload {
  return {
    id,
    username: (data.username as string | undefined) ?? '',
    imageUrl: (data.imageUrl as string | undefined) ?? '',
    friendCode: (data.friendCode as string | undefined) ?? fallbackFriendCode ?? '',
  };
}
