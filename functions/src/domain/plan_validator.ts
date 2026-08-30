/**
 * Pure constraint engine — the single source of truth for assignment
 * validity. The LLM proposes, this validates; nothing the LLM says can
 * bypass these checks.
 */

import {
  Assignment,
  PlanningContext,
  ShiftRecord,
  TraineeAssignment,
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

export interface TraineeViolation {
  assignment: TraineeAssignment;
  reason: string;
}

export interface TraineeValidationResult {
  valid: TraineeAssignment[];
  violations: TraineeViolation[];
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

/**
 * Checks one trainee proposal against the context, the already-accepted
 * trainee assignments of the plan, and any shift assignments the plan has
 * already claimed. Returns a violation reason, or null if valid.
 */
export function checkTraineeAssignment(
  assignment: TraineeAssignment,
  context: PlanningContext,
  accepted: TraineeAssignment[],
  acceptedShifts: Assignment[] = [],
): string | null {
  const session = (context.trainingSessions ?? []).find(
    (t) => t.id === assignment.sessionId,
  );
  if (!session) return `session ${assignment.sessionId} does not exist`;
  if (session.traineeId !== null) {
    return `session ${session.id} already has a trainee`;
  }
  if (accepted.some((a) => a.sessionId === session.id)) {
    return `session ${session.id} was already filled by this plan`;
  }

  const user = context.users.find((u) => u.id === assignment.userId);
  if (!user) return `user ${assignment.userId} does not exist`;
  if (user.status !== 'available') return `user ${user.id} is ${user.status}`;
  if (session.trainerIds.includes(user.id)) {
    return `user ${user.id} is a trainer of session ${session.id}`;
  }
  // Training exists to close a gap — holders don't need it.
  if (user.certifications.includes(session.certificationId)) {
    return (
      `user ${user.id} already holds certification ` +
      `${session.certificationId}`
    );
  }

  const windows = (context.availability ?? []).filter(
    (w) => w.userId === user.id,
  );
  if (
    windows.length > 0 &&
    !windows.some(
      (w) => w.startMs <= session.startMs && w.endMs >= session.endMs,
    )
  ) {
    return `user ${user.id} is not on-site for the whole session`;
  }

  const shiftConflict = context.shifts.find(
    (s) =>
      (s.userId === user.id ||
        acceptedShifts.some((a) => a.shiftId === s.id && a.userId === user.id)) &&
      s.startMs < session.endMs &&
      session.startMs < s.endMs,
  );
  if (shiftConflict) {
    return `user ${user.id} has overlapping shift ${shiftConflict.id}`;
  }

  const sessionConflict = (context.trainingSessions ?? []).find(
    (t) =>
      t.id !== session.id &&
      (t.traineeId === user.id ||
        t.trainerIds.includes(user.id) ||
        accepted.some((a) => a.sessionId === t.id && a.userId === user.id)) &&
      t.startMs < session.endMs &&
      session.startMs < t.endMs,
  );
  if (sessionConflict) {
    return `user ${user.id} is in overlapping session ${sessionConflict.id}`;
  }

  return null;
}

/** Splits a proposed trainee plan into valid assignments and violations. */
export function validateTraineePlan(
  assignments: TraineeAssignment[],
  context: PlanningContext,
  acceptedShifts: Assignment[] = [],
): TraineeValidationResult {
  const valid: TraineeAssignment[] = [];
  const violations: TraineeViolation[] = [];
  for (const assignment of assignments) {
    const reason = checkTraineeAssignment(
      assignment,
      context,
      valid,
      acceptedShifts,
    );
    if (reason === null) {
      valid.push(assignment);
    } else {
      violations.push({ assignment, reason });
    }
  }
  return { valid, violations };
}

/** All users who could legally be the trainee of session [sessionId]. */
export function eligibleTrainees(
  sessionId: string,
  context: PlanningContext,
  accepted: TraineeAssignment[] = [],
  acceptedShifts: Assignment[] = [],
): UserRecord[] {
  return context.users.filter(
    (user) =>
      checkTraineeAssignment(
        { sessionId, userId: user.id },
        context,
        accepted,
        acceptedShifts,
      ) === null,
  );
}

/**
 * The context with accepted trainee assignments materialized onto their
 * sessions — shift validation then sees those users as busy participants.
 */
export function withTrainees(
  context: PlanningContext,
  accepted: TraineeAssignment[],
): PlanningContext {
  if (accepted.length === 0) return context;
  const traineeBySession = new Map(
    accepted.map((a) => [a.sessionId, a.userId]),
  );
  return {
    ...context,
    trainingSessions: (context.trainingSessions ?? []).map((session) =>
      traineeBySession.has(session.id)
        ? { ...session, traineeId: traineeBySession.get(session.id)! }
        : session,
    ),
  };
}
