import { describe, expect, it } from 'vitest';

import {
  checkAssignment,
  checkTraineeAssignment,
  eligibleTrainees,
  eligibleUsers,
  validatePlan,
  validateTraineePlan,
  withTrainees,
} from '../src/domain/plan_validator';
import {
  PlanningContext,
  ShiftRecord,
  TrainingRecord,
  UserRecord,
} from '../src/domain/types';

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

function training(
  id: string,
  startHour: number,
  endHour: number,
  overrides: Partial<TrainingRecord> = {},
): TrainingRecord {
  return {
    id,
    certificationId: 'certGuard',
    type: 'tutoring',
    priority: 0,
    traineeId: null,
    trainerIds: [],
    startMs: T0 + startHour * HOUR,
    endMs: T0 + endHour * HOUR,
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

  it('enforces the station org scope layer by layer', () => {
    const scoped = context({
      users: [
        user('alice', {
          site: '506',
          department: 'mesima',
          jobRole: 'hagana',
        }),
      ],
    });
    scoped.stations[0] = {
      ...scoped.stations[0],
      site: '506',
      department: 'mesima',
      jobRole: 'hagana',
    };
    const assignment = { shiftId: 's1', userId: 'alice' };
    expect(checkAssignment(assignment, scoped, [])).toBeNull();

    scoped.stations[0].site = '509';
    expect(checkAssignment(assignment, scoped, [])).toMatch(/not in unit/);

    scoped.stations[0].site = '506';
    scoped.stations[0].department = 'taavura';
    expect(checkAssignment(assignment, scoped, [])).toMatch(
      /not in department/,
    );

    scoped.stations[0].department = 'mesima';
    scoped.stations[0].jobRole = 'officer';
    expect(checkAssignment(assignment, scoped, [])).toMatch(
      /does not have the officer role/,
    );
  });

  it('treats unset scope layers as wildcards', () => {
    // The default station has no scope; a user without placement passes.
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, context(), []),
    ).toBeNull();
    // A partially scoped station only pins the layers it sets.
    const scoped = context({
      users: [user('alice', { department: 'mesima' })],
    });
    scoped.stations[0] = { ...scoped.stations[0], department: 'mesima' };
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, scoped, []),
    ).toBeNull();
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
      trainingSessions: [training('tr1', 1, 3, { trainerIds: ['alice'] })],
    });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctx, []),
    ).toMatch(/training session tr1/);

    const ctxTrainee = context({
      shifts: [shift('s1', 0, 2)],
      trainingSessions: [
        training('tr2', 1, 3, { traineeId: 'alice', trainerIds: ['bob'] }),
      ],
    });
    expect(
      checkAssignment({ shiftId: 's1', userId: 'alice' }, ctxTrainee, []),
    ).toMatch(/training session tr2/);

    // Non-overlapping session is fine.
    const ctxClear = context({
      shifts: [shift('s1', 0, 2)],
      trainingSessions: [training('tr3', 3, 5, { trainerIds: ['alice'] })],
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

describe('checkTraineeAssignment', () => {
  // bob lacks certGuard in the default context — the natural trainee.
  const openSession = () => training('tr1', 0, 2, { trainerIds: ['alice'] });

  it('accepts an available uncertified user', () => {
    const ctx = context({ trainingSessions: [openSession()] });
    expect(
      checkTraineeAssignment({ sessionId: 'tr1', userId: 'bob' }, ctx, []),
    ).toBeNull();
  });

  it('rejects unknown sessions and users', () => {
    const ctx = context({ trainingSessions: [openSession()] });
    expect(
      checkTraineeAssignment({ sessionId: 'nope', userId: 'bob' }, ctx, []),
    ).toMatch(/does not exist/);
    expect(
      checkTraineeAssignment({ sessionId: 'tr1', userId: 'nope' }, ctx, []),
    ).toMatch(/does not exist/);
  });

  it('rejects sessions that already have a trainee (doc or same plan)', () => {
    const taken = context({
      trainingSessions: [
        training('tr1', 0, 2, { traineeId: 'carol', trainerIds: ['alice'] }),
      ],
    });
    expect(
      checkTraineeAssignment({ sessionId: 'tr1', userId: 'bob' }, taken, []),
    ).toMatch(/already has a trainee/);

    const ctx = context({ trainingSessions: [openSession()] });
    expect(
      checkTraineeAssignment({ sessionId: 'tr1', userId: 'bob' }, ctx, [
        { sessionId: 'tr1', userId: 'carol' },
      ]),
    ).toMatch(/already filled by this plan/);
  });

  it('rejects holders of the certification and the session trainers', () => {
    const ctx = context({ trainingSessions: [openSession()] });
    expect(
      checkTraineeAssignment({ sessionId: 'tr1', userId: 'alice' }, ctx, []),
    ).toMatch(/already holds certification|is a trainer/);
    const selfTrain = context({
      users: [user('bob', { certifications: [] })],
      trainingSessions: [training('tr1', 0, 2, { trainerIds: ['bob'] })],
    });
    expect(
      checkTraineeAssignment(
        { sessionId: 'tr1', userId: 'bob' },
        selfTrain,
        [],
      ),
    ).toMatch(/is a trainer/);
  });

  it('rejects unavailable users', () => {
    const ctx = context({
      users: [user('bob', { certifications: [], status: 'sick' })],
      trainingSessions: [openSession()],
    });
    expect(
      checkTraineeAssignment({ sessionId: 'tr1', userId: 'bob' }, ctx, []),
    ).toMatch(/is sick/);
  });

  it('enforces presence windows over the whole session', () => {
    const ctx = context({
      trainingSessions: [openSession()],
      availability: [
        { userId: 'bob', startMs: T0 + 1 * HOUR, endMs: T0 + 5 * HOUR },
      ],
    });
    expect(
      checkTraineeAssignment({ sessionId: 'tr1', userId: 'bob' }, ctx, []),
    ).toMatch(/not on-site/);
  });

  it('rejects overlap with shifts, including same-plan assignments', () => {
    const ctx = context({
      shifts: [shift('s1', 1, 3, { userId: 'bob' })],
      trainingSessions: [openSession()],
    });
    expect(
      checkTraineeAssignment({ sessionId: 'tr1', userId: 'bob' }, ctx, []),
    ).toMatch(/overlapping shift/);

    const planCtx = context({
      shifts: [shift('s1', 1, 3)],
      trainingSessions: [openSession()],
    });
    expect(
      checkTraineeAssignment({ sessionId: 'tr1', userId: 'bob' }, planCtx, [], [
        { shiftId: 's1', userId: 'bob' },
      ]),
    ).toMatch(/overlapping shift/);
  });

  it('rejects overlap with other sessions the user participates in', () => {
    const ctx = context({
      trainingSessions: [
        openSession(),
        training('tr2', 1, 3, { traineeId: 'bob', trainerIds: ['alice'] }),
      ],
    });
    expect(
      checkTraineeAssignment({ sessionId: 'tr1', userId: 'bob' }, ctx, []),
    ).toMatch(/overlapping session/);
  });
});

describe('validateTraineePlan + withTrainees', () => {
  it('splits a plan and makes accepted trainees busy for shifts', () => {
    const ctx = context({
      // stationB requires no certifications — the trainee could man it.
      shifts: [shift('s1', 1, 3, { stationId: 'stationB' })],
      trainingSessions: [training('tr1', 0, 2, { trainerIds: ['alice'] })],
    });
    const { valid, violations } = validateTraineePlan(
      [
        { sessionId: 'tr1', userId: 'bob' },
        { sessionId: 'tr1', userId: 'bob' }, // duplicate fill
      ],
      ctx,
    );
    expect(valid).toEqual([{ sessionId: 'tr1', userId: 'bob' }]);
    expect(violations).toHaveLength(1);

    // The trainee is now busy 0–2, so the overlapping 1–3 shift is illegal.
    const busyCtx = withTrainees(ctx, valid);
    expect(
      checkAssignment({ shiftId: 's1', userId: 'bob' }, busyCtx, []),
    ).toMatch(/training session tr1/);
  });
});

describe('eligibleTrainees', () => {
  it('returns only uncertified, free candidates', () => {
    const ctx = context({
      trainingSessions: [training('tr1', 0, 2, { trainerIds: ['alice'] })],
    });
    expect(eligibleTrainees('tr1', ctx).map((u) => u.id)).toEqual(['bob']);
  });
});
