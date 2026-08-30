import { z } from 'zod';

/** Structured output contract for autoFillSchedule. */
export const AutoFillPlanSchema = z.object({
  assignments: z.array(
    z.object({
      shiftId: z.string(),
      userId: z.string(),
      reason: z.string().describe('One short sentence for the manager'),
    }),
  ),
  traineeAssignments: z
    .array(
      z.object({
        sessionId: z.string(),
        userId: z.string(),
        reason: z.string().describe('One short sentence for the manager'),
      }),
    )
    .describe(
      'Trainees for open training sessions (traineeId null in context); ' +
        'empty when none can be filled',
    ),
  notes: z
    .string()
    .describe('Overall remarks: unfillable shifts, fairness trade-offs'),
});

export type AutoFillPlan = z.infer<typeof AutoFillPlanSchema>;

/** Structured output contract for suggestReplacement. */
export const ReplacementRankingSchema = z.object({
  candidates: z.array(
    z.object({
      userId: z.string(),
      rank: z.number().int().min(1),
      reason: z.string().describe('Why this person is a good replacement'),
    }),
  ),
});

export type ReplacementRanking = z.infer<typeof ReplacementRankingSchema>;
