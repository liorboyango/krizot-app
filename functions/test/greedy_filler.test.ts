import { describe, expect, it } from 'vitest';

import { fillGreedy, fillTrainingGreedy } from '../src/domain/greedy_filler';
import { validatePlan, validateTraineePlan } from '../src/domain/plan_validator';
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
  stationId: string,
  startHour: number,
  endHour: number,
): ShiftRecord {
  return {
    id,
    stationId,
    userId: null,
    startMs: T0 + startHour * HOUR,
    endMs: T0 + endHour * HOUR,
    dayKey: '2026-09-01',
  };
}

function user(id: string, certifications: string[]): UserRecord {
  return { id, displayName: id, certifications, status: 'available', fcmTokens: {} };
}

const ctx: PlanningContext = {
  users: [
    user('specialist', ['certMedic', 'certGuard']),
    user('generalist', ['certGuard']),
  ],
  stations: [
    {
      id: 'medbay',
      name: 'Medbay',
      status: 'active',
      requiredCertifications: ['certMedic'],
    },
    {
      id: 'gate',
      name: 'Gate',
      status: 'active',
      requiredCertifications: ['certGuard'],
    },
  ],
  shifts: [shift('medShift', 'medbay', 0, 2), shift('gateShift', 'gate', 0, 2)],
  maxDailyHours: 12,
};

describe('fillGreedy', () => {
  it('saves the scarce specialist for the shift only they can cover', () => {
    const plan = fillGreedy(ctx);
    expect(plan).toHaveLength(2);
    const byShift = Object.fromEntries(plan.map((a) => [a.shiftId, a.userId]));
    expect(byShift.medShift).toBe('specialist');
    expect(byShift.gateShift).toBe('generalist');
  });

  it('produces only validator-legal assignments', () => {
    const plan = fillGreedy(ctx);
    const { violations } = validatePlan(plan, ctx);
    expect(violations).toEqual([]);
  });

  it('leaves impossible shifts unfilled', () => {
    const impossible: PlanningContext = {
      ...ctx,
      users: [user('generalist', ['certGuard'])],
    };
    const plan = fillGreedy(impossible);
    expect(plan.map((a) => a.shiftId)).toEqual(['gateShift']);
  });

  it('respects assignments already accepted from the LLM', () => {
    const plan = fillGreedy(ctx, [
      { shiftId: 'gateShift', userId: 'specialist' },
    ]);
    // Specialist is busy at the gate → medbay has no legal candidate.
    expect(plan).toEqual([]);
  });
});

function training(
  id: string,
  startHour: number,
  endHour: number,
  overrides: Partial<TrainingRecord> = {},
): TrainingRecord {
  return {
    id,
    certificationId: 'certMedic',
    type: 'tutoring',
    priority: 0,
    traineeId: null,
    trainerIds: ['specialist'],
    startMs: T0 + startHour * HOUR,
    endMs: T0 + endHour * HOUR,
    ...overrides,
  };
}

describe('fillTrainingGreedy', () => {
  it('gives the scarce candidate to the higher-priority session', () => {
    // Two concurrent sessions, one uncertified candidate — priority decides.
    const trainingCtx: PlanningContext = {
      ...ctx,
      shifts: [],
      trainingSessions: [
        training('lowPrio', 0, 2, { priority: 1 }),
        training('highPrio', 0, 2, { priority: 5 }),
      ],
    };
    const plan = fillTrainingGreedy(trainingCtx);
    expect(plan).toEqual([
      {
        sessionId: 'highPrio',
        userId: 'generalist',
        reason: expect.stringContaining('greedy'),
      },
    ]);
  });

  it('produces only validator-legal trainee assignments', () => {
    const trainingCtx: PlanningContext = {
      ...ctx,
      trainingSessions: [training('tr1', 4, 6), training('tr2', 6, 8)],
    };
    const plan = fillTrainingGreedy(trainingCtx);
    expect(plan).toHaveLength(2);
    const { violations } = validateTraineePlan(plan, trainingCtx);
    expect(violations).toEqual([]);
  });

  it('skips sessions whose slot the LLM already filled and respects shift plans', () => {
    const trainingCtx: PlanningContext = {
      ...ctx,
      trainingSessions: [training('tr1', 0, 2)],
    };
    expect(
      fillTrainingGreedy(trainingCtx, [
        { sessionId: 'tr1', userId: 'generalist' },
      ]),
    ).toEqual([]);
    // The only candidate is on a same-plan overlapping shift → unfillable.
    expect(
      fillTrainingGreedy(trainingCtx, [], [
        { shiftId: 'gateShift', userId: 'generalist' },
      ]),
    ).toEqual([]);
  });
});
