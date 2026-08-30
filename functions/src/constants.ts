/** Cloud Functions region, colocated with the Firestore database. */
export const REGION = 'me-west1';

/** Named Firestore database — this project has no (default) database. */
export const DATABASE_ID = 'israel-1';

export const COLLECTION_USERS = 'users';
export const COLLECTION_CERTIFICATIONS = 'certifications';
export const COLLECTION_STATIONS = 'stations';
export const COLLECTION_SHIFTS = 'shifts';
export const COLLECTION_EVENT_TYPES = 'eventTypes';
export const COLLECTION_EMERGENCY_EVENTS = 'emergencyEvents';
export const COLLECTION_ACKS = 'acks';
export const COLLECTION_CONFIG = 'config';
export const COLLECTION_AVAILABILITY = 'availability';
export const COLLECTION_DAY_REQUIREMENTS = 'dayRequirements';
export const COLLECTION_TRAINING_SESSIONS = 'trainingSessions';

/**
 * Local timezone of the operation — dayKeys are local dates, so generating
 * a day's shifts needs the local midnight of that day.
 */
export const SCHEDULE_TIMEZONE = 'Asia/Jerusalem';

/** Auto-generated shift block length. Managers can edit any occurrence. */
export const DEFAULT_SHIFT_MINUTES = 120;
/** Hard cap on any auto-generated shift block. */
export const MAX_SHIFT_MINUTES = 180;

export const DEFAULT_MAX_DAILY_HOURS = 12;
export const DEFAULT_MAX_REPAIR_ATTEMPTS = 2;
export const DEFAULT_LLM_PROVIDER = 'anthropic';
export const DEFAULT_LLM_MODEL = 'claude-opus-5';
