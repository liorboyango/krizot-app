/**
 * Plain domain records decoupled from Firestore so the validator and the
 * greedy filler stay pure and unit-testable.
 */

export type UserStatus = 'available' | 'sick' | 'unavailable';

export interface UserRecord {
  id: string;
  displayName: string;
  certifications: string[];
  status: UserStatus;
  fcmTokens: Record<string, unknown>;
}

export interface StationRecord {
  id: string;
  name: string;
  status: 'active' | 'closed';
  requiredCertifications: string[];
}

export interface ShiftRecord {
  id: string;
  stationId: string;
  userId: string | null;
  /** Epoch milliseconds — keeps the domain layer free of Timestamp types. */
  startMs: number;
  endMs: number;
  dayKey: string;
}

export interface Assignment {
  shiftId: string;
  userId: string;
  reason?: string;
}

/** One presence window on a user's availability calendar. */
export interface AvailabilityRecord {
  userId: string;
  startMs: number;
  endMs: number;
}

/** A training session blocking its participants for its duration. */
export interface TrainingRecord {
  id: string;
  traineeId: string | null;
  trainerIds: string[];
  startMs: number;
  endMs: number;
}

export interface PlanningContext {
  users: UserRecord[];
  stations: StationRecord[];
  /** Every shift of the planning day (open and assigned). */
  shifts: ShiftRecord[];
  maxDailyHours: number;
  /**
   * Presence windows overlapping the planning range. A user with at least
   * one window here must have a window covering any shift they take; a user
   * with none is treated as always-present (legacy, no calendar).
   */
  availability?: AvailabilityRecord[];
  /** Training sessions of the planning day — participants are busy. */
  trainingSessions?: TrainingRecord[];
}
