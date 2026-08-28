/**
 * suggestReplacement({shiftId})
 *
 * The validator pre-filters the candidate pool; the LLM only ranks and
 * explains. No writes — the manager applies a suggestion through the normal
 * assignment path.
 */

import * as logger from 'firebase-functions/logger';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

import { COLLECTION_SHIFTS, REGION } from '../constants';
import {
  getDb,
  loadLlmConfig,
  loadShiftsForDay,
  loadStations,
  loadUsers,
  shiftFromDoc,
} from '../domain/firestore';
import { eligibleUsers } from '../domain/plan_validator';
import { PlanningContext, ShiftRecord } from '../domain/types';
import { generateStructured } from '../llm/llm_client';
import { buildReplacementPrompt, REPLACEMENT_SYSTEM } from '../llm/prompts';
import { ReplacementRankingSchema } from '../llm/schemas';
import { llmSecrets } from '../secrets';
import { requireRole } from './auth_guard';

const MAX_SUGGESTIONS = 3;

export const suggestReplacement = onCall(
  { region: REGION, enforceAppCheck: true, secrets: llmSecrets, timeoutSeconds: 120 },
  async (request) => {
    requireRole(request, ['admin', 'manager']);
    const shiftId = request.data?.shiftId as string | undefined;
    if (!shiftId) {
      throw new HttpsError('invalid-argument', 'shiftId is required.');
    }

    const shiftSnapshot = await getDb()
      .collection(COLLECTION_SHIFTS)
      .doc(shiftId)
      .get();
    if (!shiftSnapshot.exists) {
      throw new HttpsError('not-found', `Shift ${shiftId} does not exist.`);
    }
    const shift = shiftFromDoc(
      shiftSnapshot as FirebaseFirestore.QueryDocumentSnapshot,
    );

    const [config, users, stations, dayShifts] = await Promise.all([
      loadLlmConfig(),
      loadUsers(),
      loadStations(),
      loadShiftsForDay(shift.dayKey),
    ]);

    // Evaluate the shift as if open, excluding its current (dropped) assignee.
    const openShift: ShiftRecord = { ...shift, userId: null };
    const context: PlanningContext = {
      users: users.filter((user) => user.id !== shift.userId),
      stations,
      shifts: dayShifts.map((s) => (s.id === shift.id ? openShift : s)),
      maxDailyHours: config.maxDailyHours,
    };
    const candidates = eligibleUsers(openShift, context);
    if (candidates.length === 0) {
      return { candidates: [] };
    }

    const nameOf = (userId: string) =>
      users.find((user) => user.id === userId)?.displayName ?? userId;

    // Single eligible candidate — nothing to rank.
    if (candidates.length === 1) {
      return {
        candidates: [
          {
            userId: candidates[0].id,
            displayName: nameOf(candidates[0].id),
            rank: 1,
            reason: 'Only certified, available, conflict-free candidate.',
          },
        ],
      };
    }

    const candidateIds = new Set(candidates.map((user) => user.id));
    try {
      const ranking = await generateStructured({
        config,
        schema: ReplacementRankingSchema,
        system: REPLACEMENT_SYSTEM,
        prompt: buildReplacementPrompt(openShift, candidates, context),
      });
      const ranked = ranking.candidates
        .filter((candidate) => candidateIds.has(candidate.userId))
        .sort((a, b) => a.rank - b.rank)
        .slice(0, MAX_SUGGESTIONS)
        .map((candidate, index) => ({
          userId: candidate.userId,
          displayName: nameOf(candidate.userId),
          rank: index + 1,
          reason: candidate.reason,
        }));
      if (ranked.length > 0) return { candidates: ranked };
    } catch (error) {
      logger.error('LLM ranking failed, returning unranked candidates', error);
    }

    // Fallback: unranked, validator-approved candidates.
    return {
      candidates: candidates.slice(0, MAX_SUGGESTIONS).map((user, index) => ({
        userId: user.id,
        displayName: user.displayName,
        rank: index + 1,
        reason: 'Certified, available and conflict-free.',
      })),
    };
  },
);
