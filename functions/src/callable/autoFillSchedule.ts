/**
 * autoFillSchedule({date: 'YYYY-MM-DD'})
 *
 * LLM proposes → validator filters → violations re-prompted (repair loop) →
 * greedy filler covers whatever is left → per-shift transactional commit
 * (re-checking openness). Always returns a legal, possibly partial, fill.
 */

import { FieldValue } from 'firebase-admin/firestore';
import * as logger from 'firebase-functions/logger';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

import { COLLECTION_SHIFTS, REGION } from '../constants';
import {
  getDb,
  loadAvailabilityOverlapping,
  loadLlmConfig,
  loadShiftsForDay,
  loadStations,
  loadTrainingForDay,
  loadUsers,
} from '../domain/firestore';
import { fillGreedy } from '../domain/greedy_filler';
import { validatePlan, Violation } from '../domain/plan_validator';
import { Assignment, PlanningContext } from '../domain/types';
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

    const [config, users, stations, shifts, trainingSessions] =
      await Promise.all([
        loadLlmConfig(),
        loadUsers(),
        loadStations(),
        loadShiftsForDay(dayKey),
        loadTrainingForDay(dayKey),
      ]);
    const openCount = shifts.filter((s) => s.userId === null).length;
    if (openCount === 0) {
      return { filled: 0, unfilled: [], notes: 'No open shifts on this day.' };
    }
    // Presence windows overlapping the day's shifts.
    const availability = await loadAvailabilityOverlapping(
      Math.min(...shifts.map((s) => s.startMs)),
      Math.max(...shifts.map((s) => s.endMs)),
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
    let accepted: Assignment[] = [];
    let notes = '';
    let violations: Violation[] = [];
    for (let attempt = 0; attempt <= config.maxRepairAttempts; attempt++) {
      try {
        const plan = await generateStructured({
          config,
          schema: AutoFillPlanSchema,
          system: AUTO_FILL_SYSTEM,
          prompt: buildAutoFillPrompt(context, dayKey, violations, instructions),
        });
        notes = plan.notes;
        const result = validatePlan(
          plan.assignments.map((a) => ({ ...a })),
          context,
        );
        accepted = result.valid;
        violations = result.violations;
        logger.info(
          `autoFill attempt ${attempt}: ${accepted.length} valid, ` +
            `${violations.length} violations`,
        );
        if (violations.length === 0) break;
      } catch (error) {
        logger.error('LLM planning failed, falling back to greedy', error);
        break;
      }
    }

    // Deterministic fallback for anything still open.
    const greedyAdditions = fillGreedy(context, accepted);
    const finalPlan = [...accepted, ...greedyAdditions];

    // Commit per shift, re-checking openness to survive concurrent edits.
    const db = getDb();
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
    return { filled: committed.length, unfilled, notes };
  },
);
