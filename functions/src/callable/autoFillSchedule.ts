/**
 * autoFillSchedule({date: 'YYYY-MM-DD'})
 *
 * Missing shifts are created first (each station's manning windows split
 * into 2h-default / 3h-max blocks), then: LLM proposes trainees for open
 * training sessions (higher priority first) plus shift assignments →
 * validator filters both → violations re-prompted (repair loop) → greedy
 * fillers cover whatever is left → per-document transactional commit
 * (re-checking openness). Always returns a legal, possibly partial, fill.
 */

import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import * as logger from 'firebase-functions/logger';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

import {
  COLLECTION_SHIFTS,
  COLLECTION_TRAINING_SESSIONS,
  DEFAULT_SHIFT_MINUTES,
  MAX_SHIFT_MINUTES,
  REGION,
  SCHEDULE_TIMEZONE,
} from '../constants';
import {
  getDb,
  loadAvailabilityOverlapping,
  loadLlmConfig,
  loadShiftsForDay,
  loadStations,
  loadTrainingForDay,
  loadUsers,
} from '../domain/firestore';
import { fillGreedy, fillTrainingGreedy } from '../domain/greedy_filler';
import {
  TraineeViolation,
  validatePlan,
  validateTraineePlan,
  Violation,
  withTrainees,
} from '../domain/plan_validator';
import {
  generateMissingShifts,
  zonedDayStartMs,
} from '../domain/shift_generator';
import {
  Assignment,
  PlanningContext,
  ShiftRecord,
  TraineeAssignment,
} from '../domain/types';
import { generateStructured } from '../llm/llm_client';
import { AUTO_FILL_SYSTEM, buildAutoFillPrompt } from '../llm/prompts';
import { AutoFillPlanSchema } from '../llm/schemas';
import { llmSecrets } from '../secrets';
import { requireRole } from './auth_guard';

export const autoFillSchedule = onCall(
  { region: REGION, enforceAppCheck: true, secrets: llmSecrets, timeoutSeconds: 300 },
  async (request) => {
    const uid = requireRole(request, ['admin', 'manager']);
    const dayKey = request.data?.date as string | undefined;
    if (!dayKey || !/^\d{4}-\d{2}-\d{2}$/.test(dayKey)) {
      throw new HttpsError('invalid-argument', 'date must be YYYY-MM-DD.');
    }
    const rawInstructions = request.data?.instructions;
    if (rawInstructions !== undefined && typeof rawInstructions !== 'string') {
      throw new HttpsError('invalid-argument', 'instructions must be a string.');
    }
    // Advisory manager guidance for the LLM — hard constraints still win.
    const instructions = rawInstructions?.trim().slice(0, 2000) || undefined;

    const [config, users, stations, existingShifts, trainingSessions] =
      await Promise.all([
        loadLlmConfig(),
        loadUsers(),
        loadStations(),
        loadShiftsForDay(dayKey),
        loadTrainingForDay(dayKey),
      ]);

    // Create every still-missing shift of the day before assigning anyone:
    // stations only define WHEN manning is needed — block durations are
    // generated here and each occurrence stays individually editable.
    const db = getDb();
    const dayStartMs = zonedDayStartMs(dayKey, SCHEDULE_TIMEZONE);
    const specs = generateMissingShifts(
      stations,
      existingShifts,
      dayKey,
      dayStartMs,
      dayStartMs + 24 * 3_600_000,
      { defaultMinutes: DEFAULT_SHIFT_MINUTES, maxMinutes: MAX_SHIFT_MINUTES },
    );
    const created: ShiftRecord[] = [];
    let batch = db.batch();
    let batchOps = 0;
    for (const spec of specs) {
      const ref = db.collection(COLLECTION_SHIFTS).doc();
      batch.set(ref, {
        stationId: spec.stationId,
        userId: null,
        start: Timestamp.fromMillis(spec.startMs),
        end: Timestamp.fromMillis(spec.endMs),
        dayKey: spec.dayKey,
        status: 'open',
        acknowledged: false,
        ackAt: null,
        source: 'autoFill',
        createdBy: uid,
        lastModifiedBy: uid,
        lastModifiedAt: FieldValue.serverTimestamp(),
      });
      created.push({ id: ref.id, userId: null, ...spec });
      if (++batchOps >= 450) {
        await batch.commit();
        batch = db.batch();
        batchOps = 0;
      }
    }
    if (batchOps > 0) await batch.commit();
    logger.info(`autoFill ${dayKey}: created ${created.length} missing shifts`);

    const shifts = [...existingShifts, ...created];
    const openCount = shifts.filter((s) => s.userId === null).length;
    const openTrainingCount = trainingSessions.filter(
      (t) => t.traineeId === null,
    ).length;
    if (openCount === 0 && openTrainingCount === 0) {
      return {
        filled: 0,
        created: 0,
        unfilled: [],
        trainingFilled: 0,
        trainingUnfilled: [],
        notes: 'No open shifts or training slots on this day.',
      };
    }
    // Presence windows overlapping the day's shifts and training sessions.
    const plannedRanges = [...shifts, ...trainingSessions];
    const availability = await loadAvailabilityOverlapping(
      Math.min(...plannedRanges.map((s) => s.startMs)),
      Math.max(...plannedRanges.map((s) => s.endMs)),
    );
    const context: PlanningContext = {
      users,
      stations,
      shifts,
      maxDailyHours: config.maxDailyHours,
      availability,
      trainingSessions,
    };

    // LLM plan with repair loop — advisory only; the validator decides.
    // Trainees are validated first so shift checks see them as busy.
    let accepted: Assignment[] = [];
    let acceptedTrainees: TraineeAssignment[] = [];
    let notes = '';
    let violations: Violation[] = [];
    let traineeViolations: TraineeViolation[] = [];
    for (let attempt = 0; attempt <= config.maxRepairAttempts; attempt++) {
      try {
        const plan = await generateStructured({
          config,
          schema: AutoFillPlanSchema,
          system: AUTO_FILL_SYSTEM,
          prompt: buildAutoFillPrompt(
            context,
            dayKey,
            violations,
            traineeViolations,
            instructions,
          ),
        });
        notes = plan.notes;
        const traineeResult = validateTraineePlan(
          plan.traineeAssignments.map((a) => ({ ...a })),
          context,
        );
        acceptedTrainees = traineeResult.valid;
        traineeViolations = traineeResult.violations;
        const result = validatePlan(
          plan.assignments.map((a) => ({ ...a })),
          withTrainees(context, acceptedTrainees),
        );
        accepted = result.valid;
        violations = result.violations;
        logger.info(
          `autoFill attempt ${attempt}: ${accepted.length} valid, ` +
            `${acceptedTrainees.length} trainees, ` +
            `${violations.length + traineeViolations.length} violations`,
        );
        if (violations.length === 0 && traineeViolations.length === 0) break;
      } catch (error) {
        logger.error('LLM planning failed, falling back to greedy', error);
        break;
      }
    }

    // Deterministic fallback for anything still open — training first
    // (highest priority wins scarce candidates), then shifts around it.
    const greedyTrainees = fillTrainingGreedy(
      context,
      acceptedTrainees,
      accepted,
    );
    const finalTraineePlan = [...acceptedTrainees, ...greedyTrainees];
    const greedyAdditions = fillGreedy(
      withTrainees(context, finalTraineePlan),
      accepted,
    );
    const finalPlan = [...accepted, ...greedyAdditions];

    // Commit per document, re-checking openness to survive concurrent edits.
    // Trainees first — they were planned before the shift assignments.
    const committedTrainees: TraineeAssignment[] = [];
    for (const assignment of finalTraineePlan) {
      const ref = db
        .collection(COLLECTION_TRAINING_SESSIONS)
        .doc(assignment.sessionId);
      try {
        await db.runTransaction(async (tx) => {
          const snapshot = await tx.get(ref);
          if (!snapshot.exists || snapshot.data()?.traineeId != null) {
            throw new Error('no longer open');
          }
          tx.update(ref, {
            traineeId: assignment.userId,
            lastModifiedBy: uid,
            lastModifiedAt: FieldValue.serverTimestamp(),
          });
        });
        committedTrainees.push(assignment);
      } catch {
        logger.warn(`Skipped session ${assignment.sessionId}: no longer open`);
      }
    }

    const committed: Assignment[] = [];
    for (const assignment of finalPlan) {
      const ref = db.collection(COLLECTION_SHIFTS).doc(assignment.shiftId);
      try {
        await db.runTransaction(async (tx) => {
          const snapshot = await tx.get(ref);
          if (!snapshot.exists || snapshot.data()?.userId != null) {
            throw new Error('no longer open');
          }
          tx.update(ref, {
            userId: assignment.userId,
            status: 'assigned',
            source: 'autoFill',
            acknowledged: false,
            ackAt: null,
            notes: assignment.reason ?? null,
            lastModifiedBy: uid,
            lastModifiedAt: FieldValue.serverTimestamp(),
          });
        });
        committed.push(assignment);
      } catch {
        logger.warn(`Skipped shift ${assignment.shiftId}: no longer open`);
      }
    }

    const committedIds = new Set(committed.map((a) => a.shiftId));
    const unfilled = shifts
      .filter((s) => s.userId === null && !committedIds.has(s.id))
      .map((s) => s.id);
    const committedSessionIds = new Set(
      committedTrainees.map((a) => a.sessionId),
    );
    const trainingUnfilled = trainingSessions
      .filter((t) => t.traineeId === null && !committedSessionIds.has(t.id))
      .map((t) => t.id);
    return {
      filled: committed.length,
      created: created.length,
      unfilled,
      trainingFilled: committedTrainees.length,
      trainingUnfilled,
      notes,
    };
  },
);
