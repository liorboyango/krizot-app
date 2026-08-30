/**
 * Typed accessors over the named Firestore database. Everything backend-side
 * must go through getDb() — this project has no (default) database.
 */

import { getFirestore, Firestore, Timestamp } from 'firebase-admin/firestore';

import {
  COLLECTION_AVAILABILITY,
  COLLECTION_CONFIG,
  COLLECTION_SHIFTS,
  COLLECTION_STATIONS,
  COLLECTION_TRAINING_SESSIONS,
  COLLECTION_USERS,
  DATABASE_ID,
  DEFAULT_LLM_MODEL,
  DEFAULT_LLM_PROVIDER,
  DEFAULT_MAX_DAILY_HOURS,
  DEFAULT_MAX_REPAIR_ATTEMPTS,
} from '../constants';
import {
  AvailabilityRecord,
  ShiftRecord,
  StationRecord,
  TrainingRecord,
  UserRecord,
} from './types';

export function getDb(): Firestore {
  return getFirestore(DATABASE_ID);
}

export interface LlmConfig {
  provider: 'anthropic' | 'google' | 'xai';
  model: string;
  temperature?: number;
  maxRepairAttempts: number;
  maxDailyHours: number;
}

export async function loadLlmConfig(): Promise<LlmConfig> {
  const snapshot = await getDb()
    .collection(COLLECTION_CONFIG)
    .doc('llm')
    .get();
  const data = snapshot.data() ?? {};
  return {
    provider: (data.provider as LlmConfig['provider']) ?? DEFAULT_LLM_PROVIDER,
    model: (data.model as string) ?? DEFAULT_LLM_MODEL,
    temperature: data.temperature as number | undefined,
    maxRepairAttempts:
      (data.maxRepairAttempts as number) ?? DEFAULT_MAX_REPAIR_ATTEMPTS,
    maxDailyHours: (data.maxDailyHours as number) ?? DEFAULT_MAX_DAILY_HOURS,
  };
}

export async function loadUsers(): Promise<UserRecord[]> {
  const snapshot = await getDb().collection(COLLECTION_USERS).get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      displayName: (data.displayName as string) ?? '',
      certifications: (data.certifications as string[]) ?? [],
      status: (data.status as UserRecord['status']) ?? 'available',
      fcmTokens: (data.fcmTokens as Record<string, unknown>) ?? {},
      site: data.site as string | undefined,
      department: data.department as string | undefined,
      jobRole: data.jobRole as string | undefined,
    };
  });
}

/** 'HH:mm' → minutes from midnight. */
function parseHhmm(value: string | undefined): number {
  const [hours, minutes] = (value ?? '').split(':').map(Number);
  if (Number.isNaN(hours)) return 0;
  return hours * 60 + (Number.isNaN(minutes) ? 0 : minutes);
}

export async function loadStations(): Promise<StationRecord[]> {
  const snapshot = await getDb().collection(COLLECTION_STATIONS).get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      name: (data.name as string) ?? '',
      status: (data.status as StationRecord['status']) ?? 'active',
      requiredCertifications: (data.requiredCertifications as string[]) ?? [],
      manningType: data.manningType === '24x7' ? '24x7' : 'onDemand',
      activeWindows: (
        (data.activeWindows as { start?: string; end?: string }[]) ?? []
      ).map((window) => ({
        startMinutes: parseHhmm(window.start),
        endMinutes: parseHhmm(window.end),
      })),
      capacity: (data.capacity as number) ?? 1,
      site: data.site as string | undefined,
      department: data.department as string | undefined,
      jobRole: data.jobRole as string | undefined,
    };
  });
}

export async function loadShiftsForDay(dayKey: string): Promise<ShiftRecord[]> {
  const snapshot = await getDb()
    .collection(COLLECTION_SHIFTS)
    .where('dayKey', '==', dayKey)
    .get();
  return snapshot.docs.map(shiftFromDoc);
}

/**
 * Presence windows overlapping [startMs, endMs). Single-field query on
 * `end`; the start-side bound is filtered in memory.
 */
export async function loadAvailabilityOverlapping(
  startMs: number,
  endMs: number,
): Promise<AvailabilityRecord[]> {
  const snapshot = await getDb()
    .collection(COLLECTION_AVAILABILITY)
    .where('end', '>', Timestamp.fromMillis(startMs))
    .get();
  return snapshot.docs
    .map((doc) => {
      const data = doc.data();
      return {
        userId: (data.userId as string) ?? '',
        startMs: data.start?.toMillis?.() ?? 0,
        endMs: data.end?.toMillis?.() ?? 0,
      };
    })
    .filter((window) => window.startMs < endMs);
}

export async function loadTrainingForDay(
  dayKey: string,
): Promise<TrainingRecord[]> {
  const snapshot = await getDb()
    .collection(COLLECTION_TRAINING_SESSIONS)
    .where('dayKey', '==', dayKey)
    .get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      traineeId: (data.traineeId as string | null) ?? null,
      trainerIds: (data.trainerIds as string[]) ?? [],
      startMs: data.start?.toMillis?.() ?? 0,
      endMs: data.end?.toMillis?.() ?? 0,
    };
  });
}

export function shiftFromDoc(
  doc: FirebaseFirestore.QueryDocumentSnapshot,
): ShiftRecord {
  const data = doc.data();
  return {
    id: doc.id,
    stationId: (data.stationId as string) ?? '',
    userId: (data.userId as string | null) ?? null,
    startMs: data.start?.toMillis?.() ?? 0,
    endMs: data.end?.toMillis?.() ?? 0,
    dayKey: (data.dayKey as string) ?? '',
  };
}
