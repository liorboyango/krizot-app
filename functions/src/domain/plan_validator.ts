/**
 * Pure constraint engine — the single source of truth for assignment
 * validity. The LLM proposes, this validates; nothing the LLM says can
 * bypass these checks.
 */

import {
  Assignment,
  PlanningContext,
  ShiftRecord,
  UserRecord,
} from './types';

export interface Violation {
  assignment: Assignment;
  reason: string;
}

export interface ValidationResult {
  valid: Assignment[];
  violations: Violation[];
}

function overlaps(aStartMs: number, aEndMs: number, shift: ShiftRecord): boolean {
  return aStartMs < shift.endMs && shift.startMs < aEndMs;
}

/**
 * Checks one assignment against the context plus the already-accepted
 * assignments of the same plan. Returns a violation reason, or null if valid.
 */
export function checkAssignment(
  assignment: Assignment,
  context: PlanningContext,
  accepted: Assignment[],
): string | null {
  const shift = context.shifts.find((s) => s.id === assignment.shiftId);
  if (!shift) return `shift ${assignment.shiftId} does not exist`;
  if (shift.userId !== null) return `shift ${shift.id} is already assigned`;
  if (accepted.some((a) => a.shiftId === shift.id)) {
    return `shift ${shift.id} was already filled by this plan`;
  }

  const user = context.users.find((u) => u.id === assignment.userId);
  if (!user) return `user ${assignment.userId} does not exist`;
  if (user.status !== 'available') return `user ${user.id} is ${user.status}`;

  const station = context.stations.find((s) => s.id === shift.stationId);
  if (!station) return `station ${shift.stationId} does not exist`;
  if (station.status !== 'active') return `station ${station.id} is closed`;

  // Org scope: every layer the station pins must match the user's placement.
  if (station.site && user.site !== station.site) {
    return `user ${user.id} is not in unit ${station.site}`;
  }
  if (station.department && user.department !== station.department) {
    return `user ${user.id} is not in department ${station.department}`;
  }
  if (station.jobRole && user.jobRole !== station.jobRole) {
    return `user ${user.id} does not have the ${station.jobRole} role`;
  }

  const missing = station.requiredCertifications.filter(
    (cert) => !user.certifications.includes(cert),
  );
  if (missing.length > 0) {
    return `user ${user.id} lacks certification(s): ${missing.join(', ')}`;
  }

  // Availability calendar: a user with presence windows must have one that
  // fully covers the shift; a user with no windows is treated as present.
  const windows = (context.availability ?? []).filter(
    (w) => w.userId === user.id,
  );
  if (
    windows.length > 0 &&
    !windows.some((w) => w.startMs <= shift.startMs && w.endMs >= shift.endMs)
  ) {
    return `user ${user.id} is not on-site for the whole shift`;
  }

  const training = (context.trainingSessions ?? []).find(
    (t) =>
      (t.traineeId === user.id || t.trainerIds.includes(user.id)) &&
      shift.startMs < t.endMs &&
      t.startMs < shift.endMs,
  );
  if (training) {
    return `user ${user.id} is in training session ${training.id} at that time`;
  }

  const userShiftIds = new Set(
    accepted.filter((a) => a.userId === user.id).map((a) => a.shiftId),
  );
  const userShifts = context.shifts.filter(
    (s) => s.userId === user.id || userShiftIds.has(s.id),
  );
  const conflict = userShifts.find((s) => overlaps(shift.startMs, shift.endMs, s));
  if (conflict) {
    return `user ${user.id} already has overlapping shift ${conflict.id}`;
  }

  const plannedHours =
    userShifts
      .filter((s) => s.dayKey === shift.dayKey)
      .reduce((sum, s) => sum + (s.endMs - s.startMs), 0) /
    3_600_000;
  const shiftHours = (shift.endMs - shift.startMs) / 3_600_000;
  if (plannedHours + shiftHours > context.maxDailyHours) {
    return (
      `assigning user ${user.id} would exceed the daily cap of ` +
      `${context.maxDailyHours}h (${(plannedHours + shiftHours).toFixed(1)}h)`
    );
  }

  return null;
}

/** Splits a proposed plan into valid assignments and violations. */
export function validatePlan(
  assignments: Assignment[],
  context: PlanningContext,
): ValidationResult {
  const valid: Assignment[] = [];
  const violations: Violation[] = [];
  for (const assignment of assignments) {
    const reason = checkAssignment(assignment, context, valid);
    if (reason === null) {
      valid.push(assignment);
    } else {
      violations.push({ assignment, reason });
    }
  }
  return { valid, violations };
}

/** All users who could legally take [shift] given the current context. */
export function eligibleUsers(
  shift: ShiftRecord,
  context: PlanningContext,
  accepted: Assignment[] = [],
): UserRecord[] {
  return context.users.filter(
    (user) =>
      checkAssignment(
        { shiftId: shift.id, userId: user.id },
        context,
        accepted,
      ) === null,
  );
}
