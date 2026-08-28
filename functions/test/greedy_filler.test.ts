import { describe, expect, it } from 'vitest';

import { fillGreedy } from '../src/domain/greedy_filler';
import { validatePlan } from '../src/domain/plan_validator';
import { PlanningContext, ShiftRecord, UserRecord } from '../src/domain/types';

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
