/**
 * Prompt builders: compress the day's roster + constraints into compact JSON
 * context. Times are rendered as ISO strings for readability.
 */

import { PlanningContext, ShiftRecord, UserRecord } from '../domain/types';
import { TraineeViolation, Violation } from '../domain/plan_validator';

export const AUTO_FILL_SYSTEM = `You are a shift-scheduling assistant with
two tasks: assign users to open shifts, and assign trainees to open training
sessions (those with traineeId null).
Hard constraints for shift assignments (violations are rejected):
- The user must hold ALL certifications required by the shift's station.
- A station carrying site/department/jobRole tags may only be manned by
  users whose corresponding tags are equal; untagged layers accept anyone.
- The user's status must be "available".
- No overlapping shifts for the same user.
- A user's total assigned hours in the day must not exceed the stated cap.
- A user listed under presenceWindows may only take shifts fully inside one
  of their windows; users without windows are always on-site.
- A training session's participants (trainee + trainers, including trainees
  you assign in this plan) must not get a shift that overlaps it.
Hard constraints for trainee assignments (violations are rejected):
- The trainee must NOT already hold the session's certification.
- The trainee must not be one of the session's trainers.
- The trainee's status must be "available".
- The presence-window rule above applies to the whole session.
- No overlap with the trainee's shifts (existing or assigned in this plan)
  or with other training sessions they participate in.
Soft goals, in order: fill as many open shifts as possible; when trainee
candidates are scarce, fill higher-priority training sessions first (higher
number = more important); balance workload fairly across users; avoid
back-to-back shifts for the same user when alternatives exist. Only
reference shiftIds, sessionIds and userIds from the context.`;

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
    // Organizational placement — lets manager instructions reference units,
    // departments and roles ("only 506", "spread officers", …).
    ...(user.site ? { site: user.site } : {}),
    ...(user.department ? { department: user.department } : {}),
    ...(user.jobRole ? { jobRole: user.jobRole } : {}),
  };
}

export function buildAutoFillPrompt(
  context: PlanningContext,
  dayKey: string,
  violations: Violation[] = [],
  traineeViolations: TraineeViolation[] = [],
  instructions?: string,
): string {
  const payload = {
    date: dayKey,
    maxDailyHours: context.maxDailyHours,
    stations: context.stations.map((station) => ({
      stationId: station.id,
      name: station.name,
      requiredCertifications: station.requiredCertifications,
      // Org scope: only users matching every set layer are eligible.
      ...(station.site ? { site: station.site } : {}),
      ...(station.department ? { department: station.department } : {}),
      ...(station.jobRole ? { jobRole: station.jobRole } : {}),
    })),
    users: context.users.map(userLine),
    openShifts: context.shifts.filter((s) => s.userId === null).map(shiftLine),
    existingAssignments: context.shifts
      .filter((s) => s.userId !== null)
      .map(shiftLine),
    presenceWindows: (context.availability ?? []).map((window) => ({
      userId: window.userId,
      start: new Date(window.startMs).toISOString(),
      end: new Date(window.endMs).toISOString(),
    })),
    // traineeId null = an open slot the plan should fill with a trainee.
    trainingSessions: (context.trainingSessions ?? []).map((session) => ({
      sessionId: session.id,
      certificationId: session.certificationId,
      type: session.type,
      priority: session.priority,
      traineeId: session.traineeId,
      trainerIds: session.trainerIds,
      start: new Date(session.startMs).toISOString(),
      end: new Date(session.endMs).toISOString(),
    })),
  };
  let prompt =
    'Fill the open shifts and the open training sessions.' +
    `\n\nContext:\n${JSON.stringify(payload, null, 1)}`;
  if (instructions) {
    prompt +=
      '\n\nManager instructions (soft preferences — never override the ' +
      `hard constraints):\n${instructions}`;
  }
  if (violations.length > 0 || traineeViolations.length > 0) {
    prompt +=
      '\n\nYour previous plan had these violations — fix them and do not ' +
      'repeat them:\n' +
      [
        ...violations.map(
          (v) =>
            `- shift ${v.assignment.shiftId} → user ${v.assignment.userId}: ${v.reason}`,
        ),
        ...traineeViolations.map(
          (v) =>
            `- session ${v.assignment.sessionId} → trainee ${v.assignment.userId}: ${v.reason}`,
        ),
      ].join('\n');
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
