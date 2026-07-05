import { createHash } from 'crypto';

export const MAX_ATTEMPTS = 5;
export const LOCKOUT_MS = 15 * 60 * 1000;

export interface StoredCredentials {
  pinHash: string;
  salt: string | null;
}

export interface AttemptState {
  failCount: number;
  lockedUntilMillis: number | null;
}

export function hashPin(pin: string): string {
  return createHash('sha256').update(pin).digest('hex');
}

export function saltedPinHash(pin: string, salt: string): string {
  return createHash('sha256').update(salt + pin).digest('hex');
}

export function checkPin(stored: StoredCredentials, pin: string): boolean {
  const expected =
    stored.salt === null ? hashPin(pin) : saltedPinHash(pin, stored.salt);
  return stored.pinHash === expected;
}

export function evaluateAttempt(
  state: AttemptState | null,
  nowMillis: number,
): { lockedOut: boolean; lockedUntilMillis: number | null } {
  if (
    state?.lockedUntilMillis != null &&
    state.lockedUntilMillis > nowMillis
  ) {
    return { lockedOut: true, lockedUntilMillis: state.lockedUntilMillis };
  }
  return { lockedOut: false, lockedUntilMillis: null };
}

// failCount intentionally never decays on its own; only a lockout expiring
// resets it back to 0 (see the lockoutExpired check below).
export function recordFailure(
  state: AttemptState | null,
  nowMillis: number,
): AttemptState {
  if (evaluateAttempt(state, nowMillis).lockedOut) {
    return state!;
  }
  const lockoutExpired =
    state?.lockedUntilMillis != null && state.lockedUntilMillis <= nowMillis;
  const previousCount = state === null || lockoutExpired ? 0 : state.failCount;
  const failCount = previousCount + 1;
  return {
    failCount,
    lockedUntilMillis: failCount >= MAX_ATTEMPTS ? nowMillis + LOCKOUT_MS : null,
  };
}
