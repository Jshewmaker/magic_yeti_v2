import {
  hashPin,
  saltedPinHash,
  checkPin,
  evaluateAttempt,
  recordFailure,
  MAX_ATTEMPTS,
  LOCKOUT_MS,
} from '../src/pin-logic';

describe('hashing', () => {
  test('hashPin matches known sha256 of "0742"', () => {
    // echo -n 0742 | shasum -a 256
    expect(hashPin('0742')).toBe(
      'a2f8d2eed38aea1c4e9a90af0a0ad9fc833b5f923afc5c7709745e56f766c87c',
    );
  });

  test('salted hash differs from unsalted and is stable', () => {
    const salted = saltedPinHash('0742', 'abc123');
    expect(salted).not.toBe(hashPin('0742'));
    expect(saltedPinHash('0742', 'abc123')).toBe(salted);
  });
});

describe('checkPin', () => {
  test('legacy credentials (salt null) validate with plain hash', () => {
    expect(checkPin({ pinHash: hashPin('1234'), salt: null }, '1234')).toBe(true);
    expect(checkPin({ pinHash: hashPin('1234'), salt: null }, '4321')).toBe(false);
  });

  test('salted credentials validate with salted hash', () => {
    const stored = { pinHash: saltedPinHash('1234', 's4lt'), salt: 's4lt' };
    expect(checkPin(stored, '1234')).toBe(true);
    expect(checkPin(stored, '0000')).toBe(false);
  });
});

describe('lockout state machine', () => {
  const NOW = 1_000_000;

  test('null state is not locked out', () => {
    expect(evaluateAttempt(null, NOW)).toEqual({
      lockedOut: false,
      lockedUntilMillis: null,
    });
  });

  test('recordFailure increments and locks at MAX_ATTEMPTS', () => {
    let state = recordFailure(null, NOW); // 1
    for (let i = 1; i < MAX_ATTEMPTS - 1; i++) state = recordFailure(state, NOW);
    expect(state.failCount).toBe(MAX_ATTEMPTS - 1);
    expect(state.lockedUntilMillis).toBeNull();

    state = recordFailure(state, NOW); // 5th failure
    expect(state.failCount).toBe(MAX_ATTEMPTS);
    expect(state.lockedUntilMillis).toBe(NOW + LOCKOUT_MS);
    expect(evaluateAttempt(state, NOW + 1).lockedOut).toBe(true);
  });

  test('lockout expires and a new failure starts a fresh count', () => {
    const locked = { failCount: 5, lockedUntilMillis: NOW + LOCKOUT_MS };
    const after = NOW + LOCKOUT_MS + 1;
    expect(evaluateAttempt(locked, after).lockedOut).toBe(false);
    expect(recordFailure(locked, after)).toEqual({
      failCount: 1,
      lockedUntilMillis: null,
    });
  });

  test('recordFailure during an active lockout does not extend it', () => {
    const locked = { failCount: 5, lockedUntilMillis: NOW + LOCKOUT_MS };
    expect(recordFailure(locked, NOW + 1)).toEqual(locked);
  });
});
