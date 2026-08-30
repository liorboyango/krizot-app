import { describe, expect, it } from 'vitest';

import {
  checkAssignment,
  eligibleUsers,
  validatePlan,
} from '../src/domain/plan_validator';
import { PlanningContext, ShiftRecord, UserRecord } from '../src/domain/types';

const HOUR = 3_600_000;
const T0 = Date.parse('2026-09-01T08:00:00Z');

function shift(
  id: string,
  startHour: number,
  endHour: number,
  overrides: Partial<ShiftRecord> = {},
): ShiftRecord {
  return {
    id,
    stationId: 'stationA',
    userId: null,
    startMs: T0 + startHour * HOUR,
    endMs: T0 + endHour * HOUR,
    dayKey: '2026-09-01',
    ...overrides,
  };
}

function user(id: string, overrides: Partial<UserRecord> = {}): UserRecord {
  return {
    id,
    displayName: id,
    certifications: ['certGuard'],
    status: 'available',
    fcmTokens: {},
    ...overrides,
  };
}

function context(overrides: Partial<PlanningContext> = {}): PlanningContext {
  return {
    users: [user('alice'), user('bob', { certifications: [] })],
    stations: [
      {
        id: 'stationA',
        name: 'Station A',
        status: 'active',
        requiredCertifications: ['certGuard'],
      },
      {
        id: 'stationB',
        name: 'Station B',
        status: 'active',
        requiredCertifications: [],
      },
    ],
    shifts: [shift('s1', 0, 2)],
    maxDailyHours: 12,
    ...overrides,
  };
}

describe('checkAssignment', () => {
  it('accepts a certified, free, available user', () => {
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, context(), []),
    ).toBeNull();
  });

  it('rejects unknown shifts and users', () => {
    expect(
      checkAssignment({ shiftId: 'nope', userId: 'alice' }, context(), []),
    ).toMatch(/does not exist/);
    expect(
      checkAssignment({ shiftId: 's1', userId: 'nope' }, context(), []),
    ).toMatch(/does not exist/);
  });

  it('rejects already-assigned shifts', () => {
    const ctx = context({ shifts: [shift('s1', 0, 2, { userId: 'bob' })] });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctx, []),
    ).toMatch(/already assigned/);
  });

  it('rejects missing certifications', () => {
    expect(
      checkAssignment({ shiftId: 's1', userId: 'bob' }, context(), []),
    ).toMatch(/lacks certification/);
  });

  it('rejects sick and unavailable users', () => {
    const ctx = context({
      users: [user('alice', { status: 'sick' })],
    });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctx, []),
    ).toMatch(/is sick/);
  });

  it('rejects overlapping shifts (existing and same-plan)', () => {
    const ctx = context({
      shifts: [shift('s1', 0, 2), shift('s2', 1, 3, { userId: 'alice' })],
    });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctx, []),
    ).toMatch(/overlapping/);

    const ctx2 = context({ shifts: [shift('s1', 0, 2), shift('s2', 1, 3)] });
    expect(
      checkAssignment({ shiftId: 's2', userId: 'alice' }, ctx2, [
        { shiftId: 's1', userId: 'alice' },
      ]),
    ).toMatch(/overlapping/);
  });

  it('enforces presence windows when the user has any', () => {
    const ctx = context({
      shifts: [shift('s1', 0, 2)],
      availability: [
        // Window covering only hours 1–5 — misses the shift's first hour.
        { userId: 'alice', startMs: T0 + 1 * HOUR, endMs: T0 + 5 * HOUR },
      ],
    });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctx, []),
    ).toMatch(/not on-site/);

    const ctxCovered = context({
      shifts: [shift('s1', 0, 2)],
      availability: [
        { userId: 'alice', startMs: T0 - 1 * HOUR, endMs: T0 + 5 * HOUR },
      ],
    });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctxCovered, []),
    ).toBeNull();

    // No windows at all → legacy always-present behaviour.
    const ctxLegacy = context({
      shifts: [shift('s1', 0, 2)],
      availability: [
        { userId: 'someone-else', startMs: T0, endMs: T0 + 2 * HOUR },
      ],
    });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctxLegacy, []),
    ).toBeNull();
  });

  it('rejects users busy in an overlapping training session', () => {
    const ctx = context({
      shifts: [shift('s1', 0, 2)],
      trainingSessions: [
        {
          id: 'tr1',
          traineeId: null,
          trainerIds: ['alice'],
          startMs: T0 + 1 * HOUR,
          endMs: T0 + 3 * HOUR,
        },
      ],
    });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctx, []),
    ).toMatch(/training session tr1/);

    const ctxTrainee = context({
      shifts: [shift('s1', 0, 2)],
      trainingSessions: [
        {
          id: 'tr2',
          traineeId: 'alice',
          trainerIds: ['bob'],
          startMs: T0 + 1 * HOUR,
          endMs: T0 + 3 * HOUR,
        },
      ],
    });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctxTrainee, []),
    ).toMatch(/training session tr2/);

    // Non-overlapping session is fine.
    const ctxClear = context({
      shifts: [shift('s1', 0, 2)],
      trainingSessions: [
        {
          id: 'tr3',
          traineeId: null,
          trainerIds: ['alice'],
          startMs: T0 + 3 * HOUR,
          endMs: T0 + 5 * HOUR,
        },
      ],
    });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctxClear, []),
    ).toBeNull();
  });

  it('allows back-to-back but not beyond the daily cap', () => {
    const ctx = context({
      shifts: [shift('s1', 0, 8, { userId: 'alice' }), shift('s2', 8, 13)],
      maxDailyHours: 12,
    });
    expect(
      checkAssignment({ shiftId: 's2', userId: 'alice' }, ctx, []),
    ).toMatch(/daily cap/);

    const ctxOk = context({
      shifts: [shift('s1', 0, 8, { userId: 'alice' }), shift('s2', 8, 12)],
      maxDailyHours: 12,
    });
    expect(
      checkAssignment({ shiftId: 's2', userId: 'alice' }, ctxOk, []),
    ).toBeNull();
  });
});

describe('validatePlan', () => {
  it('splits a canned bad LLM plan into valid + violations', () => {
    const ctx = context({
      shifts: [shift('s1', 0, 2), shift('s2', 4, 6)],
    });
    const { valid, violations } = validatePlan(
      [
        { shiftId: 's1', userId: 'alice' },
        { shiftId: 's1', userId: 'alice' }, // duplicate fill
        { shiftId: 's2', userId: 'bob' }, // uncertified
        { shiftId: 'ghost', userId: 'alice' }, // nonexistent
      ],
      ctx,
    );
    expect(valid).toEqual([{ shiftId: 's1', userId: 'alice' }]);
    expect(violations).toHaveLength(3);
  });
});

describe('eligibleUsers', () => {
  it('returns only legal candidates', () => {
    const candidates = eligibleUsers(shift('s1', 0, 2), context(), []);
    expect(candidates.map((u) => u.id)).toEqual(['alice']);
  });
});
