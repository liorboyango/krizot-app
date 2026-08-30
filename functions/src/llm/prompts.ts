/**
 * Prompt builders: compress the day's roster + constraints into compact JSON
 * context. Times are rendered as ISO strings for readability.
 */

import { PlanningContext, ShiftRecord, UserRecord } from '../domain/types';
import { Violation } from '../domain/plan_validator';

export const AUTO_FILL_SYSTEM = `You are a shift-scheduling assistant.
Assign users to open shifts. Hard constraints (violations are rejected):
- The user must hold ALL certifications required by the shift's station.
- The user's status must be "available".
- No overlapping shifts for the same user.
- A user's total assigned hours in the day must not exceed the stated cap.
Soft goals, in order: fill as many open shifts as possible; balance workload
fairly across users; avoid back-to-back shifts for the same user when
alternatives exist. Only reference shiftIds and userIds from the context.`;

export const REPLACEMENT_SYSTEM = `You are a shift-scheduling assistant.
A shift lost its assignee. Rank the pre-validated candidates for taking it
over (rank 1 = best). Consider: workload balance that day, similar past
stations, minimizing schedule disruption. Only reference userIds from the
candidate list.`;

function shiftLine(shift: ShiftRecord): Record<string, unknown> {
  return {
    shiftId: shift.id,
    stationId: shift.stationId,
    userId: shift.userId,
    start: new Date(shift.startMs).toISOString(),
    end: new Date(shift.endMs).toISOString(),
  };
}

function userLine(user: UserRecord): Record<string, unknown> {
  return {
    userId: user.id,
    name: user.displayName,
    certifications: user.certifications,
    status: user.status,
  };
}

export function buildAutoFillPrompt(
  context: PlanningContext,
  dayKey: string,
  violations: Violation[] = [],
  instructions?: string,
): string {
  const payload = {
    date: dayKey,
    maxDailyHours: context.maxDailyHours,
    stations: context.stations.map((station) => ({
      stationId: station.id,
      name: station.name,
      requiredCertifications: station.requiredCertifications,
    })),
    users: context.users.map(userLine),
    openShifts: context.shifts.filter((s) => s.userId === null).map(shiftLine),
    existingAssignments: context.shifts
      .filter((s) => s.userId !== null)
      .map(shiftLine),
  };
  let prompt = `Fill the open shifts.\n\nContext:\n${JSON.stringify(payload, null, 1)}`;
  if (instructions) {
    prompt +=
      '\n\nManager instructions (soft preferences — never override the ' +
      `hard constraints):\n${instructions}`;
  }
  if (violations.length > 0) {
    prompt +=
      '\n\nYour previous plan had these violations — fix them and do not ' +
      'repeat them:\n' +
      violations
        .map(
          (v) =>
            `- shift ${v.assignment.shiftId} → user ${v.assignment.userId}: ${v.reason}`,
        )
        .join('\n');
  }
  return prompt;
}

export function buildReplacementPrompt(
  shift: ShiftRecord,
  candidates: UserRecord[],
  context: PlanningContext,
): string {
  const payload = {
    shiftToCover: shiftLine(shift),
    candidates: candidates.map((user) => ({
      ...userLine(user),
      hoursThatDay:
        context.shifts
          .filter((s) => s.userId === user.id && s.dayKey === shift.dayKey)
          .reduce((sum, s) => sum + (s.endMs - s.startMs), 0) / 3_600_000,
    })),
    otherShiftsThatDay: context.shifts
      .filter((s) => s.id !== shift.id)
      .map(shiftLine),
  };
  return `Rank the candidates.\n\nContext:\n${JSON.stringify(payload, null, 1)}`;
}
