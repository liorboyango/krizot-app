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

export interface PlanningContext {
  users: UserRecord[];
  stations: StationRecord[];
  /** Every shift of the planning day (open and assigned). */
  shifts: ShiftRecord[];
  maxDailyHours: number;
}
