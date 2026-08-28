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

export const DEFAULT_MAX_DAILY_HOURS = 12;
export const DEFAULT_MAX_REPAIR_ATTEMPTS = 2;
export const DEFAULT_LLM_PROVIDER = 'anthropic';
export const DEFAULT_LLM_MODEL = 'claude-opus-5';
