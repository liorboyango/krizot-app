/**
 * Deterministic fallback assigner: fills whatever open shifts the LLM plan
 * left (or everything, if the LLM is unavailable). Strategy: process shifts
 * with the fewest eligible candidates first; give each shift the eligible
 * candidate with the least workload that day.
 */

import { Assignment, PlanningContext } from './types';
import { eligibleUsers } from './plan_validator';

export function fillGreedy(
  context: PlanningContext,
  accepted: Assignment[] = [],
): Assignment[] {
  const additions: Assignment[] = [];
  const all = () => [...accepted, ...additions];

  const openShifts = context.shifts.filter(
    (shift) =>
      shift.userId === null && !all().some((a) => a.shiftId === shift.id),
  );

  // Fewest options first, so scarce specialists aren't wasted on shifts
  // anyone could cover.
  const ranked = openShifts
    .map((shift) => ({
      shift,
      candidates: eligibleUsers(shift, context, all()),
    }))
    .sort((a, b) => a.candidates.length - b.candidates.length);

  for (const { shift } of ranked) {
    // Re-evaluate: earlier picks may have consumed a candidate.
    const candidates = eligibleUsers(shift, context, all());
    if (candidates.length === 0) continue;

    const workloadOf = (userId: string) =>
      context.shifts
        .filter((s) => s.dayKey === shift.dayKey)
        .filter(
          (s) =>
            s.userId === userId ||
            all().some((a) => a.shiftId === s.id && a.userId === userId),
        )
        .reduce((sum, s) => sum + (s.endMs - s.startMs), 0);

    candidates.sort((a, b) => workloadOf(a.id) - workloadOf(b.id));
    additions.push({
      shiftId: shift.id,
      userId: candidates[0].id,
      reason: 'greedy fallback: least-loaded eligible candidate',
    });
  }

  return additions;
}
