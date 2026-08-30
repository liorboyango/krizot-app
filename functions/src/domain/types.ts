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
  /** Organizational placement — advisory context for the LLM planner. */
  site?: string;
  department?: string;
  jobRole?: string;
}

/** A daily manning window, minutes from local midnight. An end at/below the
 * start crosses midnight into the next day. */
export interface StationWindow {
  startMinutes: number;
  endMinutes: number;
}

export interface StationRecord {
  id: string;
  name: string;
  status: 'active' | 'closed';
  requiredCertifications: string[];
  /** '24x7' needs manning around the clock; 'onDemand' only during
   * [activeWindows]. Absent = onDemand (no generation without windows). */
  manningType?: '24x7' | 'onDemand';
  activeWindows?: StationWindow[];
  /** Simultaneous people required. Defaults to 1. */
  capacity?: number;
  /** Org scope — only users matching every set layer may man the station;
   * an unset layer is a wildcard. */
  site?: string;
  department?: string;
  jobRole?: string;
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

/**
 * A training session blocking its participants for its duration. A null
 * traineeId is an open slot the planner may fill with an uncertified user.
 */
export interface TrainingRecord {
  id: string;
  /** The certification the session trains toward. */
  certificationId: string;
  type: 'simulation' | 'spectation' | 'tutoring';
  /** Higher = more important to fill (defaults to the cert's level). */
  priority: number;
  traineeId: string | null;
  trainerIds: string[];
  startMs: number;
  endMs: number;
}

/** A proposed trainee for an open training session. */
export interface TraineeAssignment {
  sessionId: string;
  userId: string;
  reason?: string;
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
